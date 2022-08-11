%
% Collection of processing function for demultiplexing and calibrating (DC), and
% related code (except bicas.proc.L1L2.demuxer).
%
% DC = Demux (demultiplex) & Calibrate
%
%
% Author: Erik P G Johansson, Uppsala, Sweden
% First created 2021-05-25
%
classdef dc
    % PROPOSAL: Automatic test code.
    % PROPOSAL: Include bicas.proc.L1L2.demuxer.
    %   CON: Too much code.
    %
    % PROPOSAL:   process_calibrate_demux()
    %           & calibrate_demux_voltages()
    %           should only accept the needed zVars and variables.
    %   NOTE: Needs some way of packaging/extracting only the relevant zVars/fields
    %         from struct.
    
    %#######################
    %#######################
    % PUBLIC STATIC METHODS
    %#######################
    %#######################
    methods(Static)
        
        
        
        % Processing function. Derive PostDC from PreDc, i.e. demux and
        % calibrate data. Function is in large part a wrapper around
        % "calibrate_demux_voltages".
        %
        % NOTE: Public function as opposed to the other demuxing/calibration
        % functions.
        %
        function PostDc = process_calibrate_demux(PreDc, InCurPd, Cal, SETTINGS, L)

            tTicToc = tic();

            % ASSERTION
            bicas.proc.L1L2.assert_PreDC(PreDc);



            % IMPLEMENTATION NOTE: Only copy fields PreDc-->PostDc which are
            % known to be needed in order to conserve memory (not sure if
            % meaningful).
            PostDc = [];



            %############################
            % DEMUX & CALIBRATE VOLTAGES
            %############################
            PostDc.Zv.DemuxerOutput = ...
                bicas.proc.L1L2.dc.calibrate_demux_voltages(PreDc, Cal, L);



            %#########################
            % Calibrate bias CURRENTS
            %#########################
            currentSAmpere = bicas.proc.L1L2.dc.convert_CUR_to_CUR_on_SCI_TIME(...
                PreDc.Zv.Epoch, InCurPd, SETTINGS, L);
            currentTm      = bicas.proc.L1L2.cal.calibrate_current_sampere_to_TM(currentSAmpere);

            currentAAmpere = nan(size(currentSAmpere));    % Variable to fill/set.
            iCalibLZv      = Cal.get_BIAS_calibration_time_L(PreDc.Zv.Epoch);
            [iFirstList, iLastList, nSs] = EJ_library.utils.split_by_change(iCalibLZv);
            L.logf('info', ...
                ['Calibrating currents -', ...
                ' One sequence of records with identical settings at a time.'])
            for iSs = 1:nSs
                iFirst = iFirstList(iSs);
                iLast  = iLastList(iSs);

                iRecords = iFirst:iLast;

                L.logf('info', 'Records %7i-%7i : %s -- %s', ...
                    iFirst, iLast, ...
                    bicas.utils.TT2000_to_UTC_str(PreDc.Zv.Epoch(iFirst)), ...
                    bicas.utils.TT2000_to_UTC_str(PreDc.Zv.Epoch(iLast)))

                for iAnt = 1:3
                    %--------------------
                    % CALIBRATE CURRENTS
                    %--------------------
                    currentAAmpere(iRecords, iAnt) = Cal.calibrate_current_TM_to_aampere(...
                        currentTm( iRecords, iAnt), iAnt, iCalibLZv(iRecords));
                end
            end
            PostDc.Zv.currentAAmpere = currentAAmpere;



            % ASSERTION
            bicas.proc.L1L2.assert_PostDC(PostDc)

            nRecords = size(PreDc.Zv.Epoch, 1);
            bicas.log_speed_profiling(L, ...
                'bicas.proc.L1L2.dc.process_calibrate_demux', tTicToc, ...
                nRecords, 'record')
        end    % process_calibrate_demux



    end    % methods(Static)



    %########################
    %########################
    % PRIVATE STATIC METHODS
    %########################
    %########################
    methods(Static, Access=private)
        
        
        
        % Demultiplex and calibrate voltages.
        %
        % NOTE: Can handle arrays of any size if the sizes are
        % consistent.
        %
        function AsrSamplesAVolt = calibrate_demux_voltages(PreDc, Cal, L)
        % PROPOSAL: Sequence of constant settings includes dt (for CWF)
        %   PROBLEM: Not clear how to implement it since it is a property of two records, not one.
        %       PROPOSAL: Use other utility function(s).
        %           PROPOSAL: Function that finds changes in dt.
        %           PROPOSAL: Function that further splits list of index intervals ~on the form iFirstList, iLastList.
        %           PROPOSAL: Write functions such that one can detect suspicious jumps in dt (under some threshold).
        %               PROPOSAL: Different policies/behaviours:
        %                   PROPOSAL: Assertion on expected constant dt.
        %                   PROPOSAL: Always split sequence at dt jumps.
        %                   PROPOSAL: Never  split sequence at dt jumps.
        %                   PROPOSAL: Have threshold on dt when expected constant dt.
        %                       PROPOSAL: Below dt jump threshold, never split sequence
        %                       PROPOSAL: Above dt jump threshold, split sequence
        %                       PROPOSAL: Above dt jump threshold, assert never/give error
        %
        % PROPOSAL: Sequence of constant settings includes constant NaN/non-NaN for CWF.
        %
        % PROPOSAL: Integrate into bicas.proc.L1L2.demuxer (as method).
        % NOTE: Calibration is really separate from the demultiplexer. Demultiplexer only needs to split into
        %       subsequences based on mux mode and latching relay, nothing else.
        %   PROPOSAL: Separate out demultiplexer. Do not call from this function.
        %
        % PROPOSAL: Function for dtSec.
        %     PROPOSAL: Some kind of assertion (assumption of) constant sampling frequency.
        %
        % PROPOSAL: Move the different conversion of CWF/SWF (one/many cell arrays) into the calibration function?!!
        %
        % PROPOSAL: Move processing of one subsequence (one for-loop iteration) into its own function.

            %tTicToc  = tic();

            % ASSERTIONS
            assert(isscalar(PreDc.hasSnapshotFormat))
            assert(iscell(  PreDc.Zv.samplesCaTm))
            EJ_library.assert.vector(PreDc.Zv.samplesCaTm)
            assert(numel(PreDc.Zv.samplesCaTm) == 5)
            bicas.proc.utils.assert_cell_array_comps_have_same_N_rows(...
                PreDc.Zv.samplesCaTm)
            [nRecords, nSamplesPerRecordChannel] = EJ_library.assert.sizes(...
                PreDc.Zv.MUX_SET,        [-1,  1], ...
                PreDc.Zv.DIFF_GAIN,      [-1,  1], ...
                PreDc.Zv.samplesCaTm{1}, [-1, -2]);



            % Pre-allocate
            % ------------
            % IMPLEMENTATION NOTE: Very important for speeding up LFR-SWF which
            % tends to be broken into subsequences of 1 record.
            tempVoltageArray = nan(nRecords, nSamplesPerRecordChannel);
            AsrSamplesAVolt = struct(...
                'dcV1',  tempVoltageArray, ...
                'dcV2',  tempVoltageArray, ...
                'dcV3',  tempVoltageArray, ...
                'dcV12', tempVoltageArray, ...
                'dcV13', tempVoltageArray, ...
                'dcV23', tempVoltageArray, ...
                'acV12', tempVoltageArray, ...
                'acV13', tempVoltageArray, ...
                'acV23', tempVoltageArray);

            dlrUsing12zv = bicas.proc.L1L2.demuxer_latching_relay(PreDc.Zv.Epoch);
            iCalibLZv    = Cal.get_BIAS_calibration_time_L(PreDc.Zv.Epoch);
            iCalibHZv    = Cal.get_BIAS_calibration_time_H(PreDc.Zv.Epoch);



            %===================================================================
            % (1) Find continuous subsequences of records with identical
            %     settings.
            % (2) Process data separately for each such sequence.
            % ----------------------------------------------------------
            % NOTE: Just finding continuous subsequences can take a significant
            %       amount of time.
            % NOTE: Empirically, this is not useful for real LFR SWF datasets
            %       where the LFR sampling frequency changes in every record,
            %       meaning that the subsequences are all 1 record long.
            % NOTE: Rx (the relevant value from R0, R1, R2) is not included
            %       since it is not needed, since data has already been
            %       separated into separate DC/AC variables.
            %
            % SS = Subsequence (single, constant value valid for entire
            %      subsequence)
            %===================================================================
            [iFirstList, iLastList, nSs] = EJ_library.utils.split_by_change(...
                PreDc.Zv.MUX_SET, ...
                PreDc.Zv.DIFF_GAIN, ...
                dlrUsing12zv, ...
                PreDc.Zv.freqHz, ...
                iCalibLZv, ...
                iCalibHZv, ...
                PreDc.Zv.iLsf, ...
                PreDc.Zv.useFillValues, ...
                PreDc.Zv.CALIBRATION_TABLE_INDEX);
            L.logf('info', ...
                ['Calibrating voltages -', ...
                ' One sequence of records with identical settings at a time.'])

            for iSs = 1:nSs

                iFirst = iFirstList(iSs);
                iLast  = iLastList (iSs);

                % Extract SCALAR settings to use for entire subsequence of
                % records.
                MUX_SET_ss                 = PreDc.Zv.MUX_SET  (              iFirst);
                DIFF_GAIN_ss               = PreDc.Zv.DIFF_GAIN(              iFirst);
                dlrUsing12_ss              = dlrUsing12zv(                    iFirst);
                freqHz_ss                  = PreDc.Zv.freqHz(                 iFirst);
                iCalibL_ss                 = iCalibLZv(                       iFirst);
                iCalibH_ss                 = iCalibHZv(                       iFirst);
                iLsf_ss                    = PreDc.Zv.iLsf(                   iFirst);
                ufv_ss                     = PreDc.Zv.useFillValues(          iFirst);
                CALIBRATION_TABLE_INDEX_ss = PreDc.Zv.CALIBRATION_TABLE_INDEX(iFirst, :);

                if ~(PreDc.hasSnapshotFormat && PreDc.isLfr)
                    % IMPLEMENTATION NOTE: Do not log for LFR SWF since it
                    % produces unnecessarily many log messages since sampling
                    % frequencies change for every CDF record.
                    %
                    % PROPOSAL: Make into "proper" table with top rows with column names.
                    %   NOTE: Can not use EJ_library.str.assist_print_table() since
                    %         it requires the entire table to pre-exist before execution.
                    %   PROPOSAL: Print after all iterations.
                    %
                    % NOTE: DIFF_GAIN needs three characters to fit in "NaN".
                    L.logf('info', ['Records %8i-%8i : %s -- %s', ...
                        ' MUX_SET=%i; DIFF_GAIN=%-3i; dlrUsing12=%i;', ...
                        ' freqHz=%5g; iCalibL=%i; iCalibH=%i; ufv=%i', ...
                        ' CALIBRATION_TABLE_INDEX=[%i, %i]'], ...
                        iFirst, iLast, ...
                        bicas.utils.TT2000_to_UTC_str(PreDc.Zv.Epoch(iFirst)), ...
                        bicas.utils.TT2000_to_UTC_str(PreDc.Zv.Epoch(iLast)), ...
                        MUX_SET_ss, DIFF_GAIN_ss, dlrUsing12_ss, freqHz_ss, ...
                        iCalibL_ss, iCalibH_ss, ufv_ss, ...
                        CALIBRATION_TABLE_INDEX_ss(1), ...
                        CALIBRATION_TABLE_INDEX_ss(2))
                end

                %=======================================
                % DEMULTIPLEXER: FIND ASR-BLTS ROUTINGS
                %=======================================
                % NOTE: Call demultiplexer with no samples. Only for collecting
                % information on which BLTS channels are connected to which
                % ASRs.
                [BltsSrcAsrArray, ~] = bicas.proc.L1L2.demuxer.main(...
                    MUX_SET_ss, dlrUsing12_ss, {[],[],[],[],[]});



                % Extract subsequence of DATA records to "demux".
                ssSamplesCaTm = bicas.proc.utils.select_row_range_from_cell_comps(...
                    PreDc.Zv.samplesCaTm, iFirst, iLast);
                % NOTE: "zVariable" (i.e. first index=record) for only the
                % current subsequence.
                ssZvNValidSamplesPerRecord = PreDc.Zv.nValidSamplesPerRecord(iFirst:iLast);
                if PreDc.hasSnapshotFormat
                    % NOTE: Vector of constant numbers (one per snapshot).
                    ssDtSec = 1 ./ PreDc.Zv.freqHz(iFirst:iLast);
                else
                    % NOTE: Scalar (one for entire sequence).
                    ssDtSec = double(...
                        PreDc.Zv.Epoch(iLast) - PreDc.Zv.Epoch(iFirst)) ...
                        / (iLast-iFirst) * 1e-9;   % TEMPORARY?
                end

                biasHighGain = DIFF_GAIN_ss;



                %=====================
                % ITERATE OVER BLTS's
                %=====================
                ssSamplesAVoltCa = cell(5,1);
                for iBlts = 1:5
                    ssSamplesAVoltCa{iBlts} = bicas.proc.L1L2.dc.calibrate_BLTS(...
                        BltsSrcAsrArray(iBlts), ...
                        ssSamplesCaTm{iBlts}, ...
                        iBlts, ...
                        PreDc.hasSnapshotFormat, ...
                        ssZvNValidSamplesPerRecord, ...
                        biasHighGain, ...
                        iCalibL_ss, ...
                        iCalibH_ss, ...
                        iLsf_ss, ...
                        ssDtSec, ...
                        PreDc.isLfr, PreDc.isTdsCwf, ...
                        CALIBRATION_TABLE_INDEX_ss, ufv_ss, ...
                        Cal);
                end    % for iBlts = 1:5

                %====================================
                % DEMULTIPLEXER: DERIVE MISSING ASRs
                %====================================
                [~, SsAsrSamplesAVolt] = bicas.proc.L1L2.demuxer.main(...
                    MUX_SET_ss, dlrUsing12_ss, ssSamplesAVoltCa);

                % Add demuxed sequence to the to-be complete set of records.
                AsrSamplesAVolt = bicas.proc.utils.set_struct_field_rows(...
                    AsrSamplesAVolt, SsAsrSamplesAVolt, iFirst:iLast);

            end    % for iSs = 1:length(iFirstList)



            % NOTE: Assumes no "return" statement.
            %bicas.log_speed_profiling(L, 'bicas.proc.L1L2.dc.calibrate_demux_voltages', tTicToc, nRecords, 'record')
            %bicas.log_memory_profiling(L, 'bicas.proc.L1L2.dc.calibrate_demux_voltages:end')
        end    % calibrate_demux_voltages



        % Calibrate one BLTS channel.
        function samplesAVolt = calibrate_BLTS(...
                BltsSrcAsr, samplesTm, iBlts, ...
                hasSnapshotFormat, ...
                zvNValidSamplesPerRecord, biasHighGain, ...
                iCalibL, iCalibH, iLsf, dtSec, ...
                isLfr, isTdsCwf, ...
                CALIBRATION_TABLE_INDEX, ufv, ...
                Cal)
            % IMPLEMENTATION NOTE: It is ugly to have this many parameters (15!),
            % but the original code made calibrate_demux_voltages() to large and
            % unwieldy. It also highlights the dependencies.
            %
            % PROPOSAL: CalSettings as parameter.
            %   PRO: Reduces number of parameters.
            %   PROPOSAL: Add values to CalSettings: isLfr, isTdsCwf, CALIBRATION_TABLE_INDEX
            %       CON: cal does not seem to use more values.

            if strcmp(BltsSrcAsr.category, 'Unknown')
                % ==> Calibrated data == NaN.
                samplesAVolt = nan(size(samplesTm));

            elseif ismember(BltsSrcAsr.category, {'GND', '2.5V Ref'})
                % ==> No calibration.
                samplesAVolt = ssSamplesTm;

            else
                assert(BltsSrcAsr.is_ASR())
                % ==> Calibrate (unless explicitly stated that should not)

                if hasSnapshotFormat
                    samplesCaTm = ...
                        bicas.proc.utils.convert_matrix_to_cell_array_of_vectors(...
                            double(samplesTm), zvNValidSamplesPerRecord);
                else
                    assert(all(zvNValidSamplesPerRecord == 1))
                    samplesCaTm = {double(samplesTm)};
                end

                %######################
                %######################
                %  CALIBRATE VOLTAGES
                %######################
                %######################
                % IMPLEMENTATION NOTE: Must explicitly disable
                % calibration for LFR zVar BW=0
                % ==> CALIBRATION_TABLE_INDEX(1,:) illegal value.
                % ==> Can not calibrate.
                % Therefore uses ufv_ss to disable calibration.
                % It is thus not enough to overwrite the values later.
                % This incidentally also potentially speeds up the code.
                % Ex: LFR SWF 2020-02-25, 2020-02-28.
                CalSettings = struct();
                CalSettings.iBlts        = iBlts;
                CalSettings.BltsSrc      = BltsSrcAsr;
                CalSettings.biasHighGain = biasHighGain;
                CalSettings.iCalibTimeL  = iCalibL;
                CalSettings.iCalibTimeH  = iCalibH;
                CalSettings.iLsf         = iLsf;
                %#######################################################
                ssSamplesCaAVolt = Cal.calibrate_voltage_all(...
                    dtSec, samplesCaTm, ...
                    isLfr, isTdsCwf, CalSettings, ...
                    CALIBRATION_TABLE_INDEX, ufv);
                %#######################################################

                if hasSnapshotFormat
                    [samplesAVolt, ~] = ...
                        bicas.proc.utils.convert_cell_array_of_vectors_to_matrix(...
                            ssSamplesCaAVolt, ...
                            size(samplesTm, 2));
                else
                    % NOTE: Must be column array.
                    samplesAVolt = ssSamplesCaAVolt{1};
                end
            end
        end    % calibrate_BLTS



        function currentSAmpere = convert_CUR_to_CUR_on_SCI_TIME(...
                sciEpoch, InCur, SETTINGS, L)
            
            % PROPOSAL: Change function name. process_* implies converting struct-->struct.

            % ASSERTIONS
            assert(isa(InCur, 'bicas.InputDataset'))



            %===================================================================
            % CDF ASSERTION: CURRENT data begins before SCI data (i.e. there is
            % enough CURRENT data).
            %===================================================================
            if ~(min(InCur.Zv.Epoch) <= min(sciEpoch))
                curRelativeSec    = 1e-9 * (min(InCur.Zv.Epoch) - min(sciEpoch));
                sciEpochUtcStr    = EJ_library.cdf.TT2000_to_UTC_str(min(sciEpoch));
                curEpochMinUtcStr = EJ_library.cdf.TT2000_to_UTC_str(min(InCur.Zv.Epoch));

                [settingValue, settingKey] = SETTINGS.get_fv(...
                    'PROCESSING.CUR.TIME_NOT_SUPERSET_OF_SCI_POLICY');

                anomalyDescrMsg = sprintf(...
                    ['Bias current data begins %g s (%s) AFTER voltage data begins (%s).', ....
                    ' Can therefore not determine currents for all voltage timestamps.'], ...
                    curRelativeSec, curEpochMinUtcStr, sciEpochUtcStr);

                bicas.default_anomaly_handling(L, settingValue, settingKey, 'E+W+illegal', ...
                    anomalyDescrMsg, 'BICAS:SWModeProcessing')
            end



            %====================================================================
            % CDF ASSERTION: Epoch increases (not monotonically)
            % --------------------------------------------------
            % NOTE: bicas.proc.L1L2.dc.zv_TC_to_current() checks (and handles)
            % that Epoch increases monotonically, but only for each antenna
            % separately (which does not capture all cases). Therefore checks
            % that Epoch is (non-monotonically) increasing.
            % Ex: Timestamps, iAntenna = mod(iRecord,3): 1,2,3,5,4,6
            %       ==> Monotonically increasing sequences for each antenna
            %           separately, but not even increasing when combined.
            %====================================================================
            assert(issorted(InCur.Zv.Epoch), ...
                'BICAS:DatasetFormat', ...
                'CURRENT timestamps zVar Epoch does not increase (all antennas combined).')

            % NOTE: bicas.proc.L1L2.dc.zv_TC_to_current() checks that Epoch
            % increases monotonically.
            currentNanoSAmpere = [];
            currentNanoSAmpere(:,1) = bicas.proc.L1L2.dc.zv_TC_to_current(InCur.Zv.Epoch, InCur.Zv.IBIAS_1, sciEpoch, L, SETTINGS);
            currentNanoSAmpere(:,2) = bicas.proc.L1L2.dc.zv_TC_to_current(InCur.Zv.Epoch, InCur.Zv.IBIAS_2, sciEpoch, L, SETTINGS);
            currentNanoSAmpere(:,3) = bicas.proc.L1L2.dc.zv_TC_to_current(InCur.Zv.Epoch, InCur.Zv.IBIAS_3, sciEpoch, L, SETTINGS);

            currentSAmpere = 1e-9 * currentNanoSAmpere;
        end
        
        
        
        % Wrapper around EJ_library.so.hwzv.CURRENT_zv_to_current_interpolate for
        % anomaly handling.
        function sciZv_IBIASx = zv_TC_to_current(...
                curZv_Epoch, curZv_IBIAS_x, sciZv_Epoch, L, SETTINGS)



            %====================
            % Calibrate currents
            %====================
            [sciZv_IBIASx, duplicateAnomaly] = ...
                EJ_library.so.hwzv.CURRENT_zv_to_current_interpolate(...
                    curZv_Epoch, ...
                    curZv_IBIAS_x, ...
                    sciZv_Epoch);



            if duplicateAnomaly
                %====================================================
                % Handle anomaly: Non-monotonically increasing Epoch
                %====================================================
                [settingValue, settingKey] = SETTINGS.get_fv(...
                    'INPUT_CDF.CUR.DUPLICATE_BIAS_CURRENT_SETTINGS_POLICY');
                anomalyDescriptionMsg = [...
                    'Bias current data contain duplicate settings, with', ...
                    ' identical timestamps', ...
                    ' and identical bias settings on the same antenna.'];

                switch(settingValue)
                    case 'REMOVE_DUPLICATES'
                        bicas.default_anomaly_handling(L, ...
                            settingValue, settingKey, 'other', ...
                            anomalyDescriptionMsg)
                        L.log('warning', ...
                            ['Removed duplicated bias current settings with', ...
                            ' identical timestamps on the same antenna.'])

                    otherwise
                        bicas.default_anomaly_handling(L, ...
                            settingValue, settingKey, 'E+illegal', ...
                            anomalyDescriptionMsg, ...
                            'BICAS:SWModeProcessing:DatasetFormat')
                end
            end

        end    % bicas.proc.L1L2.dc.zv_TC_to_current



    end    % methods(Static, Access=private)

end
