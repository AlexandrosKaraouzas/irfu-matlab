%
% Collection of TDS-related processing functions.
%
%
% Author: Erik P G Johansson, Uppsala, Sweden
% First created 2021-05-25
%
classdef tds   % < handle
    % PROPOSAL: Automatic test code.



    %#######################
    %#######################
    % PUBLIC STATIC METHODS
    %#######################
    %#######################
    methods(Static)



        % Processing function. Only "normalizes" data to account for technically
        % illegal input TDS datasets. It should try to:
        % ** modify L1 to look like L1R
        % ** mitigate historical bugs in the input datasets
        % ** mitigate for not yet implemented features in input datasets
        %
        function InSciNorm = process_normalize_CDF(InSci, inSciDsi, SETTINGS, L)

            % Default behaviour: Copy values, except for values which are
            % modified later
            InSciNorm = InSci;

            nRecords = EJ_library.assert.sizes(InSci.Zv.Epoch, [-1]);

            C = EJ_library.so.adm.classify_BICAS_L1_L1R_to_L2_DATASET_ID(inSciDsi);


            %===================================
            % Normalize CALIBRATION_TABLE_INDEX
            %===================================
            InSciNorm.Zv.CALIBRATION_TABLE_INDEX = bicas.proc.L1RL2.normalize_CALIBRATION_TABLE_INDEX(...
                InSci.Zv, nRecords, inSciDsi);



            %===========================================================
            % Normalize zVar name SYNCHRO_FLAG
            % --------------------------------
            % Both zVars TIME_SYNCHRO_FLAG, SYNCHRO_FLAG found in input
            % datasets. Unknown why. "DEFINITION BUG" in definition of
            % datasets/skeleton? /2020-01-05
            % Based on skeletons (.skt; L1R, L2), SYNCHRO_FLAG seems
            % to be the correct one. /2020-01-21
            %===========================================================
            [InSci.Zv, fnChangeList] = EJ_library.utils.normalize_struct_fieldnames(...
                InSci.Zv, ...
                {{{'TIME_SYNCHRO_FLAG', 'SYNCHRO_FLAG'}, 'SYNCHRO_FLAG'}}, ...
                'Assert one matching candidate');

            bicas.proc.utils.handle_zv_name_change(...
                fnChangeList, inSciDsi, SETTINGS, L, ...
                'SYNCHRO_FLAG', 'INPUT_CDF.USING_ZV_NAME_VARIANT_POLICY')



            %=========================
            % Normalize SAMPLING_RATE
            %=========================
            if any(InSci.Zv.SAMPLING_RATE == 255)
                [settingValue, settingKey] = SETTINGS.get_fv(...
                    'PROCESSING.L1R.TDS.RSWF_ZV_SAMPLING_RATE_255_POLICY');
                anomalyDescrMsg = ...
                    ['Finds illegal, stated sampling frequency', ...
                    ' 255 in TDS L1/L1R LFM-RSWF dataset.'];

                if C.isTdsRswf
                    switch(settingValue)
                        case 'CORRECT'
                            %===================================================
                            % IMPLEMENTATION NOTE: Has observed test file
                            % TESTDATA_RGTS_TDS_CALBA_V0.8.5C:
                            % solo_L1R_rpw-tds-lfm-rswf-e_20190523T080316-20190523T134337_V02_les-7ae6b5e.cdf
                            % to have SAMPLING_RATE == 255, which is likely a
                            % BUG in the dataset.
                            % /Erik P G Johansson 2019-12-03
                            % Is bug in TDS RCS.  /David Pisa 2019-12-03
                            % Setting it to what is probably the correct value.
                            %===================================================
                            InSciNorm.Zv.SAMPLING_RATE(InSci.Zv.SAMPLING_RATE == 255) = 32768;
                            L.logf('warning', ...
                                'Using workaround to modify instances of sampling frequency 255-->32768.')
                            bicas.default_anomaly_handling(L, ...
                                settingValue, settingKey, 'other', anomalyDescrMsg)

                        otherwise
                            bicas.default_anomaly_handling(L, ...
                                settingValue, settingKey, 'E+W+illegal', ...
                                anomalyDescrMsg, ...
                                'BICAS:process_normalize_CDF:DatasetFormat')
                    end
                else
                    error(anomalyDescrMsg)
                end
            end



            if C.isTdsRswf
                %============================================================
                % Check for and handle illegal input data, zVar SAMPS_PER_CH
                % ----------------------------------------------------------
                % NOTE: Has observed invalid SAMPS_PER_CH value 16562 in
                % ROC-SGSE_L1R_RPW-TDS-LFM-RSWF-E_73525cd_CNE_V03.CDF.
                % 2019-09-18, David Pisa: Not a flaw in TDS RCS but in the
                % source L1 dataset.
                %============================================================
                zv_SAMPS_PER_CH_corrected = round(2.^round(log2(double(InSci.Zv.SAMPS_PER_CH))));
                zv_SAMPS_PER_CH_corrected = cast(zv_SAMPS_PER_CH_corrected, class(InSci.Zv.SAMPS_PER_CH));
                zv_SAMPS_PER_CH_corrected = max( zv_SAMPS_PER_CH_corrected, EJ_library.so.constants.TDS_RSWF_SNAPSHOT_LENGTH_MIN);
                zv_SAMPS_PER_CH_corrected = min( zv_SAMPS_PER_CH_corrected, EJ_library.so.constants.TDS_RSWF_SNAPSHOT_LENGTH_MAX);

                if any(zv_SAMPS_PER_CH_corrected ~= InSci.Zv.SAMPS_PER_CH)
                    % CASE: SAMPS_PER_CH has at least one illegal value

                    SAMPS_PER_CH_badValues = unique(InSci.Zv.SAMPS_PER_CH(...
                        zv_SAMPS_PER_CH_corrected ~= InSci.Zv.SAMPS_PER_CH));

                    badValuesDisplayStr = strjoin(arrayfun(...
                        @(n) sprintf('%i', n), SAMPS_PER_CH_badValues, 'uni', false), ', ');
                    anomalyDescrMsg = sprintf(...
                        ['TDS LFM RSWF zVar SAMPS_PER_CH contains unexpected', ...
                        ' value(s) which are not on the form 2^n and in the', ...
                        ' interval %.0f to %.0f: %s'], ...
                        EJ_library.so.constants.TDS_RSWF_SNAPSHOT_LENGTH_MIN, ...
                        EJ_library.so.constants.TDS_RSWF_SNAPSHOT_LENGTH_MAX, ...
                        badValuesDisplayStr);

                    [settingValue, settingKey] = SETTINGS.get_fv(...
                        'PROCESSING.TDS.RSWF.ILLEGAL_ZV_SAMPS_PER_CH_POLICY');
                    switch(settingValue)
                        case 'ROUND'
                            bicas.default_anomaly_handling(...
                                L, settingValue, settingKey, 'other', ...
                                anomalyDescrMsg, ...
                                'BICAS:L1RL2:process_normalize_CDF:Assertion:DatasetFormat')
                            % NOTE: Logging the mitigation, NOT the anomaly
                            % itself.
                            L.logf('warning', ...
                                ['Replacing TDS RSWF zVar SAMPS_PER_CH', ...
                                ' values with values, rounded to valid', ...
                                ' values due to setting %s.'], ...
                                settingKey)

                            InSciNorm.Zv.SAMPS_PER_CH = zv_SAMPS_PER_CH_corrected;

                        otherwise
                            bicas.default_anomaly_handling(L, ...
                                settingValue, settingKey, 'E+W+illegal', ...
                                anomalyDescrMsg, ...
                                'BICAS:L1RL2:process_normalize_CDF:Assertion:DatasetFormat')

                    end    % switch
                end    % if
            end    % if

        end    % process_normalize_CDF



        % Processing function. Convert TDS CDF data (PDs) to PreDC.
        function PreDc = process_CDF_to_PreDC(InSci, inSciDsi, HkSciTime, SETTINGS, L)
        %
        % BUG?: Does not use CHANNEL_STATUS_INFO.
        % NOTE: BIAS output datasets do not have a variable for the length of
        % snapshots. Need to use NaN/fill value.

            % ASSERTIONS: VARIABLES
            EJ_library.assert.struct(InSci,     {'Zv', 'ZvFv', 'Ga', 'filePath'}, {})
            EJ_library.assert.struct(HkSciTime, {'MUX_SET', 'DIFF_GAIN'}, {})

            C = EJ_library.so.adm.classify_BICAS_L1_L1R_to_L2_DATASET_ID(inSciDsi);



            % ASSERTIONS: CDF
            assert(issorted(InSci.Zv.Epoch, 'strictascend'), ...
                'BICAS:process_CDF_to_PreDC:DatasetFormat', ...
                'Voltage (science) dataset timestamps Epoch do not increase monotonously.')
            [nRecords, WAVEFORM_DATA_nChannels, nCdfSamplesPerRecord] = EJ_library.assert.sizes(...
                InSci.Zv.Epoch, [-1], ...
                InSci.Zv.WAVEFORM_DATA, [-1, -2, -3]);
            if     C.isL1r   WAVEFORM_DATA_nChannels_expected = 3;
            elseif C.isL1    WAVEFORM_DATA_nChannels_expected = 8;
            end
            assert(...
                WAVEFORM_DATA_nChannels == WAVEFORM_DATA_nChannels_expected, ...
                'BICAS:L1RL2:process_CDF_to_PreDC:Assertion:DatasetFormat', ...
                'TDS zVar WAVEFORM_DATA has an unexpected size.')
            if C.isTdsRswf   assert(nCdfSamplesPerRecord == EJ_library.so.constants.TDS_RSWF_SAMPLES_PER_RECORD)
            else             assert(nCdfSamplesPerRecord == 1)
            end



            % TODO-NI: Why convert to double? To avoid precision problems when
            % doing math with other variables?
            freqHzZv = double(InSci.Zv.SAMPLING_RATE);



            PreDc = [];

            PreDc.Zv.Epoch                   = InSci.Zv.Epoch;
            PreDc.Zv.DELTA_PLUS_MINUS        = bicas.proc.utils.derive_DELTA_PLUS_MINUS(...
                freqHzZv, nCdfSamplesPerRecord);
            PreDc.Zv.freqHz                  = freqHzZv;
            PreDc.Zv.QUALITY_BITMASK         = InSci.Zv.QUALITY_BITMASK;
            PreDc.Zv.QUALITY_FLAG            = InSci.Zv.QUALITY_FLAG;
            PreDc.Zv.SYNCHRO_FLAG            = InSci.Zv.SYNCHRO_FLAG;
            PreDc.Zv.MUX_SET                 = HkSciTime.MUX_SET;
            PreDc.Zv.DIFF_GAIN               = HkSciTime.DIFF_GAIN;
            PreDc.Zv.useFillValues           = false(nRecords, 1);
            PreDc.Zv.CALIBRATION_TABLE_INDEX = InSci.Zv.CALIBRATION_TABLE_INDEX;



            %=====================================
            % Set PreDc.Zv.nValidSamplesPerRecord
            %=====================================
            if C.isTdsRswf
                %================================================================
                % NOTE: This might only be appropriate for TDS's "COMMON_MODE"
                % mode. TDS also has a "FULL_BAND" mode with 2^18=262144 samples
                % per snapshot. You should never encounter FULL_BAND in any
                % dataset (even on ground), only used for calibration and
                % testing. /David Pisa & Jan Soucek in emails, 2016.
                % --
                % FULL_BAND mode has each snapshot divided into 2^15
                % samples/record * 8 records.  /Unknown source. Unclear what
                % value SAMPS_PER_CH should have for FULL_BAND mode. How does
                % Epoch work for FULL_BAND snapshots?
                %================================================================
                % Converting to double because code did so before code
                % reorganization. Reason unknown. Needed to avoid precision
                % problems when doing math with other variables?
                PreDc.Zv.nValidSamplesPerRecord = double(InSci.Zv.SAMPS_PER_CH);
            else
                PreDc.Zv.nValidSamplesPerRecord = ones(nRecords, 1) * 1;
            end
            assert(all(PreDc.Zv.nValidSamplesPerRecord <= nCdfSamplesPerRecord), ...
                'BICAS:L1RL2:process_CDF_to_PreDC:Assertion:DatasetFormat', ...
                ['Dataset indicates that the number of valid samples per CDF', ...
                ' record (max(PreDc.Zv.nValidSamplesPerRecord)=%i) is', ...
                ' NOT fewer than the number of indices per CDF record', ...
                ' (nCdfMaxSamplesPerSnapshot=%i).'], ...
                max(PreDc.Zv.nValidSamplesPerRecord), ...
                nCdfSamplesPerRecord)



            %==========================
            % Set PreDc.Zv.samplesCaTm
            %==========================
            modif_WAVEFORM_DATA = double(permute(InSci.Zv.WAVEFORM_DATA, [1,3,2]));

            PreDc.Zv.samplesCaTm    = cell(5,1);
            PreDc.Zv.samplesCaTm{1} = bicas.proc.utils.set_NaN_after_snapshots_end( modif_WAVEFORM_DATA(:,:,1), PreDc.Zv.nValidSamplesPerRecord );
            PreDc.Zv.samplesCaTm{2} = bicas.proc.utils.set_NaN_after_snapshots_end( modif_WAVEFORM_DATA(:,:,2), PreDc.Zv.nValidSamplesPerRecord );
            PreDc.Zv.samplesCaTm{3} = bicas.proc.utils.set_NaN_after_snapshots_end( modif_WAVEFORM_DATA(:,:,3), PreDc.Zv.nValidSamplesPerRecord );
            PreDc.Zv.samplesCaTm{4} = nan(nRecords, nCdfSamplesPerRecord);
            PreDc.Zv.samplesCaTm{5} = nan(nRecords, nCdfSamplesPerRecord);



            PreDc.Ga.OBS_ID         = InSci.Ga.OBS_ID;
            PreDc.Ga.SOOP_TYPE      = InSci.Ga.SOOP_TYPE;

            PreDc.isLfr             = false;
            PreDc.isTdsCwf          = C.isTdsCwf;
            PreDc.hasSnapshotFormat = C.isTdsRswf;
            % Only set because the code shared with LFR requires it.
            PreDc.Zv.iLsf           = nan(nRecords, 1);



            % ASSERTIONS
            bicas.proc.L1RL2.assert_PreDC(PreDc)

        end    % process_CDF_to_PreDC



        % Processing function. Convert PreDc+PostDC to something that 
        % (1) represents a TDS dataset (hence the name), and
        % (2) ALMOST REPRESENTS an LFR dataset (the rest is done in a wrapper).
        %
        % This function only changes the data format (and selects data to send
        % to CDF).
        %
        function [OutSci] = process_PostDC_to_CDF(SciPreDc, SciPostDc, outputDsi, L)
            % PROPOSAL: Rename to something shared between LFR and TDS, then use
            %           two wrappers.
            %   PROPOSAL: process_PostDC_to_LFR_TDS_CDF_core
            %   TODO-DEC: Put in which future file?

            % ASSERTIONS
            bicas.proc.L1RL2.assert_PostDC(SciPostDc)



            nSamplesPerRecordChannel  = size(SciPostDc.Zv.DemuxerOutput.dcV1, 2);
            nRecords                  = size(SciPreDc.Zv.Epoch, 1);

            OutSci = [];

            OutSci.Zv.Epoch              = SciPreDc.Zv.Epoch;
            OutSci.Zv.QUALITY_BITMASK    = SciPreDc.Zv.QUALITY_BITMASK;
            OutSci.Zv.L2_QUALITY_BITMASK = SciPostDc.Zv.L2_QUALITY_BITMASK;
            OutSci.Zv.QUALITY_FLAG       = SciPreDc.Zv.QUALITY_FLAG;
            OutSci.Zv.DELTA_PLUS_MINUS   = SciPreDc.Zv.DELTA_PLUS_MINUS;
            OutSci.Zv.SYNCHRO_FLAG       = SciPreDc.Zv.SYNCHRO_FLAG;
            OutSci.Zv.SAMPLING_RATE      = SciPreDc.Zv.freqHz;

            % NOTE: Convert aampere --> nano-aampere
            OutSci.Zv.IBIAS1 = SciPostDc.Zv.currentAAmpere(:, 1) * 1e9;
            OutSci.Zv.IBIAS2 = SciPostDc.Zv.currentAAmpere(:, 2) * 1e9;
            OutSci.Zv.IBIAS3 = SciPostDc.Zv.currentAAmpere(:, 3) * 1e9;

            OutSci.Ga.OBS_ID    = SciPreDc.Ga.OBS_ID;
            OutSci.Ga.SOOP_TYPE = SciPreDc.Ga.SOOP_TYPE;



            C = EJ_library.so.adm.classify_BICAS_L1_L1R_to_L2_DATASET_ID(outputDsi);

            % NOTE: The two cases are different in the indexes they use for
            % OutSciZv.
            if C.isCwf

                % ASSERTIONS
                assert(nSamplesPerRecordChannel == 1, ...
                    'BICAS:L1RL2:Assertion:IllegalArgument', ...
                    ['Number of samples per CDF record is not 1, as expected.', ...
                    ' Bad input CDF?'])
                EJ_library.assert.sizes(...
                    OutSci.Zv.QUALITY_BITMASK, [nRecords, 1], ...
                    OutSci.Zv.QUALITY_FLAG,    [nRecords, 1])

                % Try to pre-allocate to save RAM/speed up.
                tempNaN = nan(nRecords, 3);
                OutSci.Zv.VDC = tempNaN;
                OutSci.Zv.EDC = tempNaN;
                OutSci.Zv.EAC = tempNaN;

                OutSci.Zv.VDC(:,1) = SciPostDc.Zv.DemuxerOutput.dcV1;
                OutSci.Zv.VDC(:,2) = SciPostDc.Zv.DemuxerOutput.dcV2;
                OutSci.Zv.VDC(:,3) = SciPostDc.Zv.DemuxerOutput.dcV3;

                OutSci.Zv.EDC(:,1) = SciPostDc.Zv.DemuxerOutput.dcV12;
                OutSci.Zv.EDC(:,2) = SciPostDc.Zv.DemuxerOutput.dcV13;
                OutSci.Zv.EDC(:,3) = SciPostDc.Zv.DemuxerOutput.dcV23;

                OutSci.Zv.EAC(:,1) = SciPostDc.Zv.DemuxerOutput.acV12;
                OutSci.Zv.EAC(:,2) = SciPostDc.Zv.DemuxerOutput.acV13;
                OutSci.Zv.EAC(:,3) = SciPostDc.Zv.DemuxerOutput.acV23;

            elseif C.isSwf

                if     C.isLfr
                    SAMPLES_PER_RECORD_CHANNEL = ...
                        EJ_library.so.constants.LFR_SWF_SNAPSHOT_LENGTH;
                elseif C.isTds
                    SAMPLES_PER_RECORD_CHANNEL = ...
                        EJ_library.so.constants.TDS_RSWF_SAMPLES_PER_RECORD;
                else
                    error(...
                        'BICAS:L1RL2:Assertion', ...
                        'Illegal DATASET_ID classification.')
                end

                % ASSERTION
                assert(nSamplesPerRecordChannel == SAMPLES_PER_RECORD_CHANNEL, ...
                    'BICAS:L1RL2:Assertion:IllegalArgument', ...
                    ['Number of samples per CDF record (%i) is not', ...
                    ' %i, as expected. Bad Input CDF?'], ...
                    nSamplesPerRecordChannel, ...
                    SAMPLES_PER_RECORD_CHANNEL)

                % Try to pre-allocate to save RAM/speed up.
                tempNaN = nan(nRecords, nSamplesPerRecordChannel, 3);
                OutSci.Zv.VDC = tempNaN;
                OutSci.Zv.EDC = tempNaN;
                OutSci.Zv.EAC = tempNaN;

                OutSci.Zv.VDC(:,:,1) = SciPostDc.Zv.DemuxerOutput.dcV1;
                OutSci.Zv.VDC(:,:,2) = SciPostDc.Zv.DemuxerOutput.dcV2;
                OutSci.Zv.VDC(:,:,3) = SciPostDc.Zv.DemuxerOutput.dcV3;

                OutSci.Zv.EDC(:,:,1) = SciPostDc.Zv.DemuxerOutput.dcV12;
                OutSci.Zv.EDC(:,:,2) = SciPostDc.Zv.DemuxerOutput.dcV13;
                OutSci.Zv.EDC(:,:,3) = SciPostDc.Zv.DemuxerOutput.dcV23;

                OutSci.Zv.EAC(:,:,1) = SciPostDc.Zv.DemuxerOutput.acV12;
                OutSci.Zv.EAC(:,:,2) = SciPostDc.Zv.DemuxerOutput.acV13;
                OutSci.Zv.EAC(:,:,3) = SciPostDc.Zv.DemuxerOutput.acV23;

            else
                error('BICAS:L1RL2:Assertion:IllegalArgument', ...
                    'Function can not produce outputDsi=%s.', outputDsi)
            end



            % ASSERTION
            bicas.proc.utils.assert_struct_num_fields_have_same_N_rows(OutSci.Zv);
            % NOTE: Not really necessary since the list of zVars will be checked
            % against the master CDF?
            % NOTE: Includes zVar "BW" (LFR L2 only).
            EJ_library.assert.struct(OutSci.Zv, {...
                'IBIAS1', 'IBIAS2', 'IBIAS3', 'VDC', 'EDC', 'EAC', 'Epoch', ...
                'QUALITY_BITMASK', 'L2_QUALITY_BITMASK', 'QUALITY_FLAG', ...
                'DELTA_PLUS_MINUS', 'SYNCHRO_FLAG', 'SAMPLING_RATE'}, {})

        end    % process_PostDC_to_CDF
        
        
        
    end    % methods(Static)
    
    %########################
    %########################
    % PRIVATE STATIC METHODS
    %########################
    %########################
    methods(Static, Access=private)
    end    % methods(Static, Access=private)

end
