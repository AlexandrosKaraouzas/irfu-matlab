classdef dm_utils
% Collections of minor utility functions (in the form of static methods) used by data_manager.
% The functions are collected here to reduce the size of data_manager.
% dm_utils = data_manager utilities
%
% SPR = Samples per record
%
% Author: Erik P G Johansson, IRF-U, Uppsala, Sweden
% First created 2016-10-10

%============================================================================================================
% PROPOSAL: Move some functions to "utils".
%   Ex: add_components_to_struct, select_subset_from_struct
% PROPOSAL: Write test code for ACQUISITION_TIME_to_tt2000 and inversion.
% PROPOSAL: Split up in separate files?!
% PROPOSAL: Reorg select_subset_from_struct into returning a list of intervals instead.
%
% PROPOSAL: Replace find_last_same_subsequence with function that returns list of sequences.
%   PRO: Can naturally handle zero records.
%
% N-->1 sample/record
%    NOTE: Time conversion may require moving the zero-point within the snapshot/record.
%    PROPOSAL: : All have nSamplesPerOldRecord as column vector.
%       PRO: LFR.
%    PROPOSAL: First convert column data to 2D data (with separate functions), then reshape to 1D with one common function.
%       CON: Does not work for ACQUISITION_TIME since two columns.



    methods(Static, Access=public)

        function filteredData = filter_rows(data, rowFilter)
        % Function intended for filtering out (copying selectively) data from a zVariable.
        %
        % data         : Numeric array with N rows.                 (Intended to represent zVariables with N records.)
        % rowFilter    : Numeric/logical column vector with N rows. (Intended to represent zVariables with N records.)
        % filteredData : Array of the same size as "records", with
        %                filteredData(i,:,:, ...) == NaN,                 for record_filter(i)==0.
        %                filteredData(i,:,:, ...) == records(i,:,:, ...), for record_filter(i)~=0.

            % ASSERTIONS
            if ~iscolumn(rowFilter)     % Not really necessary to require row vector, only 1D vector.
                error('BICAS:dm_utils:Assertion:IllegalArgument', 'rowFilter is not a column vector.')
            elseif size(rowFilter, 1) ~= size(data, 1)
                error('BICAS:dm_utils:Assertion:IllegalArgument', 'Numbers of records do not match.')
            elseif ~isfloat(data)
                error('BICAS:dm_utils:Assertion:IllegalArgument', 'data is not a floating-point class (can not represent NaN).')
            end
            
            
            
            % Copy all data
            filteredData = data;
            
            % Overwrite data that should not have been copied with NaN
            % --------------------------------------------------------
            % IMPLEMENTATION NOTE: Command works empirically for filteredData having any number of dimensions. However,
            % if rowFilter and filteredData have different numbers of rows, then the final array may get the wrong
            % dimensions (without triggering error!) since new array components (indices) are assigned. ==> The
            % corresponding ASSERTION is important!
            filteredData(rowFilter==0, :) = NaN;
        end



        function s = select_subset_from_struct(s, iFirst, iLast)
        % Given a struct, select a subset of that struct defined by a range of COLUMN indicies for every field.
        % Generic utility function.
        
        % PROPOSAL: Use ~assert_unvaried_N_rows.
        
            fieldNameList = fieldnames(s);
            nRows = NaN;                   % Initial non-sensical value which is later replaced.
            for i=1:length(fieldNameList)
                fn = fieldNameList{i};
                
                % ASSERTIONS
                if isnan(nRows)
                    nRows = size(s.(fn), 1);
                    if (nRows < iFirst) || (nRows < iLast)
                        error('BICAS:dm_utils:Assertion', 'iFirst or iLast outside of interval of indices (rows).')
                    end
                elseif nRows ~= size(s.(fn), 1)
                   error('BICAS:dm_utils:Assertion', 'Not all struct fields have the same number of rows.')
                end
                
                s.(fn) = s.(fn)(iFirst:iLast, :, :);
            end
        end
        
        

        function s = add_components_to_struct(s, structAmendment)
        % Add values to every struct field by adding components after their highest row index (let them grow in
        % the row index).
        
        % PROPOSAL: Better name. ~rows, ~fields
        %   Ex: add_row_components_to_struct_fields
            
            % Generic utility function.
            fieldNamesList = fieldnames(structAmendment);
            for i=1:length(fieldNamesList)
                fn = fieldNamesList{i};
                
                s.(fn) = [s.(fn) ; structAmendment.(fn)];
            end
        end



        function freq = get_LFR_frequency(FREQ)
        % Convert LFR zVariable FREQ values to Hz. The usefulness of this function stems from how the LFR
        % datasets are defined.
        %
        % FREQ : The FREQ zVariable in LFR CDFs (contains constants representing frequencies, themselves NOT being frequencies).
        % freq : Frequency in Hz.
            
            global CONSTANTS
            
            % ASSERTION
            unique_values = unique(FREQ);
            if ~all(ismember(unique_values, [0,1,2,3]))
                unique_values_str = sprintf('%d', unique_values);   % NOTE: Has to print without \n to keep all values on a single-line string.
                error('BICAS:dm_utils:Assertion:IllegalArgument:DatasetFormat', 'Found unexpected values in LFR_FREQ (unique values: %s).', unique_values_str)
            end
            
            % NOTE: Implementation that works for arrays of any size.
            freq = ones(size(FREQ)) * -1;
            freq(FREQ==0) = CONSTANTS.C.LFR.F0;
            freq(FREQ==1) = CONSTANTS.C.LFR.F1;
            freq(FREQ==2) = CONSTANTS.C.LFR.F2;
            freq(FREQ==3) = CONSTANTS.C.LFR.F3;
        end
        
        
        
        function Rx = get_LFR_Rx(R0, R1, R2, FREQ)
        % Return the relevant value of LFR CDF zVariables R0, R1, or R2, or a hypothetical but analogous "R3" which is always 1.
        %
        % R0, R1, R2, FREQ : LFR CDF zVariables. All must have identical array sizes.
        % Rx               : Same size array as R0, R1, R2, FREQ. The relevant values are copied, respectively, from
        %                    R0, R1, R2, or an analogous hypothetical "R3" that is a constant (=1) depending on
        %                    the value of FREQ in the corresponding component.
        %
        % NOTE: Works for all array sizes.
            
            Rx = -ones(size(FREQ));        % Set to -1 (should always be overwritten).
            
            I = (FREQ==0); Rx(I) = R0(I);
            I = (FREQ==1); Rx(I) = R1(I);
            I = (FREQ==2); Rx(I) = R2(I);
            I = (FREQ==3); Rx(I) = 1;      % The value of a hypothetical (non-existant, constant) analogous zVariable "R3".
        end



        function iLast = find_last_same_sequence(iFirst, varargin)
        % Finds the greatest iLast such that all varargin{k}(i) are equal for iFirst <= i <= iLast separately for every k.
        % Useful for finding a continuous sequence of records with the same data.
        %
        % ASSUMES: varargin{i} are all column arrays of the same size.
        % ASSUMES: At least one record. (Algorithm does not work for zero records. Output is ill-defined.)
        
        % PROPOSAL: Better name?
        % PROPOSAL: Replace by function that returns list of sequences.
        %   PRO: Can naturally handle zero records.
            
            % ASSERTIONS
            if 0 == length(varargin)
                error('BICAS:dm_utils:Assertion:IllegalArgument', 'There is no vectors to look for sequences in.')
            end
            for k = 1:length(varargin)
                if ~iscolumn(varargin{k})
                    error('BICAS:dm_utils:Assertion:IllegalArgument', 'varargins are not all column vectors.')
                end
            end                
            nRecords = size(varargin{1}, 1);
            if nRecords == 0
                error('BICAS:dm_utils:Assertion:IllegalArgument', 'Vectors are empty.')
            end
                
            % NOTE: Algorithm does not work for nRecords==0.
            iLast = iFirst;
            while iLast+1 <= nRecords       % For as long as there is another row...
                for k = 1:length(varargin)
                    if ~isequaln(varargin{k}(iFirst), varargin{k}(iLast+1))    % NOTE: Use equals that treats NaN as any other value.
                        % CASE: This row is different from the previous one.
                        return
                    end
                end
                iLast = iLast + 1;
            end
            iLast = nRecords;
        end



        function tt2000 = ACQUISITION_TIME_to_tt2000(ACQUISITION_TIME)
        % Convert time in from ACQUISITION_TIME to tt2000 which is used for Epoch in CDF files.
        % 
        % NOTE: t_tt2000 is in int64.
        % NOTE: ACQUSITION_TIME can not be negative since it is uint32.
            
            global CONSTANTS
            
            bicas.dm_utils.assert_ACQUISITION_TIME(ACQUISITION_TIME)
            
            ACQUISITION_TIME = double(ACQUISITION_TIME);
            atSeconds = ACQUISITION_TIME(:, 1) + ACQUISITION_TIME(:, 2) / 65536;   % at = ACQUISITION_TIME
            tt2000 = spdfcomputett2000(CONSTANTS.C.ACQUISITION_TIME_EPOCH_UTC) + int64(atSeconds * 1e9);   % NOTE: spdfcomputett2000 returns int64 (as it should).
        end
        
        
        
        function ACQUISITION_TIME = tt2000_to_ACQUISITION_TIME(tt2000)
        % Convert from tt2000 to ACQUISITION_TIME.
        %
        % t_tt2000 : Nx1 vector. Tequired to be int64 like the real zVar Epoch.
        % ACQUISITION_TIME : Nx2 vector. uint32.
        %       NOTE: ACQUSITION_TIME can not be negative since it is uint32.
        
            global CONSTANTS
            
            % ASSERTIONS
            bicas.dm_utils.assert_Epoch(tt2000)

            % NOTE: Important to type cast to double because of multiplication
            atSeconds = double(int64(tt2000) - spdfcomputett2000(CONSTANTS.C.ACQUISITION_TIME_EPOCH_UTC)) * 1e-9;    % at = ACQUISITION_TIME
            
            % ASSERTION: ACQUISITION_TIME must not be negative.
            if any(atSeconds < 0)
                error('BICAS:dm_manager:Assertion:IllegalArgument:DatasetFormat', 'Can not produce ACQUISITION_TIME (uint32) with negative number of integer seconds.')
            end
            
            atSeconds = round(atSeconds*65536) / 65536;
            atSecondsFloor = floor(atSeconds);
            
            ACQUISITION_TIME = uint32([]);
            ACQUISITION_TIME(:, 1) = uint32(atSecondsFloor);
            ACQUISITION_TIME(:, 2) = uint32((atSeconds - atSecondsFloor) * 65536);
            % NOTE: Should not be able to produce ACQUISITION_TIME(:, 2)==65536 (2^16) since atSeconds already rounded (to parts of 2^-16).
        end
        
        
        
        function utcStr = tt2000_to_UTC_str(tt2000)
        % Convert tt2000 value to UTC string with nanoseconds.
        %
        % Example: 2016-04-16T02:26:14.196334848
        % NOTE: This is the inverse to spdfparsett2000.
            
            bicas.dm_utils.assert_Epoch(tt2000)
            
            v = spdfbreakdowntt2000(tt2000);
            utcStr = sprintf('%04i-%02i-%02iT%02i:%02i:%2i.%03i%03i%03i', v(1), v(2), v(3), v(4), v(5), v(6), v(7), v(8), v(9));
        end
        
        
        
        function newData = convert_N_to_1_SPR_redistribute(oldData)
        % Convert data from N samples/record to 1 sample/record (from a matrix to a column vector).
        
            % NOTE: ndims always returns at least two, which is exactly what we want, also for empty and scalars, and row vectors.
            if ndims(oldData) > 2
                error('BICAS:dm_utils:Assertion:IllegalArgument', 'oldData has more than two dimensions.')
            end
            
            newData = reshape(oldData', numel(oldData), 1);
        end
        
        
        
        function newData = convert_N_to_1_SPR_repeat(oldData, nRepeatsPerOldRecord)
            % ASSERTIONS
            if ~(iscolumn(oldData))
                error('BICAS:dm_utils:Assertion', 'oldData is not a column vector')
            elseif ~isscalar(nRepeatsPerOldRecord)
                error('BICAS:dm_utils:Assertion', 'nSamplesPerOldRecord is not a scalar')
            end
            
            newData = repmat(oldData, [1,nRepeatsPerOldRecord]);
            newData = reshape(newData', [numel(newData), 1]);     % NOTE: Must transpose first.
        end
        
        
        
        function newTt2000 = convert_N_to_1_SPR_Epoch( oldTt2000, nSpr, frequencyWithinRecords )
        % Convert time series zVariable (column) equivalent to converting N-->1 samples/record, assuming time increments
        % with frequency in each snapshot.
        %
        % oldTt2000  : Nx1 vector.
        % newTt2000  : Nx1 vector. Like oldTt2000 but each single time (row) has been replaced by a constantly
        %              incrementing sequence of times (rows). Every such sequence begins with the original value, has
        %              length nSpr with frequency frequencyWithinRecords(i).
        %              NOTE: There is no check that the entire sequence is monotonic. LFR data can have snapshots (i.e.
        %              snapshot records) that overlap in time!
        % nSpr                    : Positive integer. Scalar. Number of values/samples per record (SPR).
        % frequencyWithinRecords  : Nx1 vector. Frequency of samples within a subsequence (CDF record). Unit: Hz.
            
        % PROPOSAL: Turn into more generic function, working on number sequences in general.
        % PROPOSAL: N_sequence should be a column vector.
        %    NOTE: TDS-LFM-RSWF, LFR-SURV-CWF have varying snapshot lengths.
        %    PRO: Could be useful for converting N->1 samples/record for calibration with transfer functions.
        %       NOTE: Then also needs function that does the reverse.
        % PROPOSAL: Replace by some simpler(?) algorithm that uses column/matrix multiplication.
            
            % ASSERTIONS
            bicas.dm_utils.assert_Epoch(oldTt2000)
            if numel(nSpr) ~= 1
                error('BICAS:dm_utils:Assertion:IllegalArgument', 'nSpr not scalar.')
            elseif size(frequencyWithinRecords, 1) ~= size(oldTt2000, 1)
                error('BICAS:dm_utils:Assertion:IllegalArgument', 'frequencyWithinRecords and oldTt2000 do not have the same number of rows.')
            end
            
            nRecords = numel(oldTt2000);
            
            % Express frequency as period length in ns (since tt2000 uses ns as a unit).
            % Use the same MATLAB class as tt
            % Unique frequency per record.
            periodNsColVec = int64(1e9 ./ frequencyWithinRecords);   
            periodNsMatrix = repmat(periodNsColVec, [1, nSpr]);
                        
            % Conventions:
            % ------------
            % Time unit: ns (as for tt2000)            
            % Algorithm should require integers to have a very predictable behaviour (useful when testing).
            
            % Times for the beginning of every record.
            tt2000RecordBeginColVec = oldTt2000;
            tt2000RecordBeginMatrix = repmat(tt2000RecordBeginColVec, [1, nSpr]);
            
            % Indices for within every record (start at zero for every record).
            iSampleRowVec = int64(0:(nSpr-1));
            iSampleMatrix = repmat(iSampleRowVec, [nRecords, 1]);
            
            % Unique time for every sample in every record.
            tt2000Matrix = tt2000RecordBeginMatrix + iSampleMatrix .* periodNsMatrix;
            
            % Convert to 2D matrix --> 1D column vector.
            newTt2000 = reshape(tt2000Matrix', [nRecords*nSpr, 1]);
        end
        
        
        
        function ACQUISITION_TIME_2 = convert_N_to_1_SPR_ACQUISITION_TIME(  ACQUISITION_TIME_1, nSpr, frequencyWithinRecords  )
        % Function intended for converting ACQUISITION_TIME (always one time per record) from many samples/record to one sample/record.
        % Analogous to convert_N_to_1_SPR_Epoch.
        % 
        % ACQUISITION_TIME_1 : Nx2 vector.
        % ACQUISITION_TIME_2 : Nx2 vector.

        % Command-line algorithm "test code":
        % clear; t_rec = [1;2;3;4]; f = [5;1;5;20]; N=length(t_rec); M=5; I_sample=repmat(0:(M-1), [N, 1]); F=repmat(f, [1,M]); T_rec = repmat(t_rec, [1,M]); T = T_rec + I_sample./F; reshape(T', [numel(T), 1])
            
            % ASSERTIONS
            bicas.dm_utils.assert_ACQUISITION_TIME(ACQUISITION_TIME_1)

            tt2000_1 = bicas.dm_utils.ACQUISITION_TIME_to_tt2000(ACQUISITION_TIME_1);
            tt2000_2 = bicas.dm_utils.convert_N_to_1_SPR_Epoch(tt2000_1, nSpr, frequencyWithinRecords);
            ACQUISITION_TIME_2 = bicas.dm_utils.tt2000_to_ACQUISITION_TIME(tt2000_2);
        end
        
        
        
        function DELTA_PLUS_MINUS = derive_DELTA_PLUS_MINUS(freq, varSize)
        % freq    : Frequency column vector in s^-1.
        % varSize : Size of the matrix to be returned. 
        % DELTA_PLUS_MINUS : Analogous to BIAS zVariable CDF_INT8=int64. NOTE: Unit ns.
        %
        % NOTE: Can not handle freq=NaN since the output is an integer.
        %
        % NOTE: The real DELTA_PLUS_MINUS is CDF_INT8.
            
            if ~iscolumn(freq) || ~isfloat(freq)
                error('BICAS:dm_utils:Assertion', '"freq" is not a column vector of floats.')
            elseif size(freq, 1) ~= varSize(1)
                error('BICAS:dm_utils:Assertion', 'The size of "freq" does not match varSize.')
            elseif length(varSize) < 2
                error('BICAS:dm_utils:Assertion', 'The "freq" is not at least two elements long.')
            end
            
            DELTA_PLUS_MINUS = zeros(varSize);             % NOTE: "zeros" creates a square matrix for scalar argument!
            for i = 1:length(freq)
                DELTA_PLUS_MINUS(i, :) = 1/freq(i) * 1e9 * 0.5;      % Seems to work for more than 2D.
            end
            DELTA_PLUS_MINUS = cast(DELTA_PLUS_MINUS, bicas.utils.convert_CDF_type_to_MATLAB_class('CDF_INT8',  'Only CDF data types'));
        end



        function newData = nearest_interpolate_float_records(oldData, oldTt2000, newTt2000)
        % Interpolate ~zVariable to other points in time using nearest neighbour interpolation.
        % Values outside the interval covered by the old time series will be set to NaN.
        %
        % This is intended for interpolating HK values to SCI record times.
        %
        % IMPLEMENTATION NOTE: interp1 does seem to require oldData to be float. Using NaN as a "fill value" for the
        % return value imples that it too has to be a float.
            
            bicas.dm_utils.assert_Epoch(oldTt2000)
            bicas.dm_utils.assert_Epoch(newTt2000)
            newData = interp1(double(oldTt2000), oldData, double(newTt2000), 'nearest', NaN);
        end


        
        function uniqueValues = unique_NaN(A)
        % Return number of unique values in array, treating +Inf, -Inf, and NaN as equal to themselves.
        % (MATLAB's "unique" function does not do this for NaN.)
        %
        % NOTE: Should work for all dimensionalities.
           
        % PROPOSAL: Move to +utils?
            
            % NOTE: "unique" has special behaviour which must be taken into account:
            % 1) Inf and -Inf are treated as equal to themselves.
            % 2) NaN is treated as if it is NOT equal itself. ==> Can thus return multiple instances of NaN.
            % 3) "unique" always puts NaN at the then of the vector of unique values (one or many NaN).
            uniqueValues = unique(A);
            
            % Remove all NaN unless it is found in the last component (save one legitimate occurrence of NaN, if there is any).
            % NOTE: Does work for empty matrices.
            uniqueValues(isnan(uniqueValues(1:end-1))) = [];
        end
        
        
        
        function log_unique_values_summary(variable_name, v)
        % Log number of unique values, and NaN, found in numeric matrix.
        % Useful for summarizin dataset data (usually many unique values).
        %
        % NOTE: Can handle zero values.
            
        % Excplicitly state including/excluding NaN? Number of NaN? Percent NaN? Min-max?
            
            N_values = length(bicas.dm_utils.unique_NaN(v));
            N_NaN = sum(isnan(v(:)));
            irf.log('n', sprintf('#Unique %-6s values: %5d (%3i%%=%6i/%6i NaN)', ...
                variable_name, N_values, ...
                round((N_NaN/numel(v))*100), ...
                N_NaN, numel(v)))
        end

        
        
        function log_unique_values_all(variableName, v)
        % Log all unique values found in numeric matrix.
        % Useful for logging dataset settings (few unique values).
        %
        % NOTE: Can handle zero values.
            
            % Automatically switch to log_unique_values_summary if too many?
            % Print number of NaN?
            %N_NaN = sum(isnan(v(:)));
            valuesStr = sprintf('%d ', bicas.dm_utils.unique_NaN(v));
            irf.log('n', sprintf('Unique %-9s values: %s', variableName, valuesStr))
        end
        
        
        
        function log_tt2000_interval(variableName, tt2000)
        % Log summary of series of times.
        %
        % tt2000 : A vector of tt2000 values.
        %
        % NOTE: Assumes that t is sorted in time, increasing.
        % NOTE: Can handle zero values.
        
            bicas.dm_utils.assert_Epoch(tt2000)
            
            if ~isempty(tt2000)
                strFirst = bicas.dm_utils.tt2000_to_UTC_str(tt2000(1));
                strLast  = bicas.dm_utils.tt2000_to_UTC_str(tt2000(end));
                irf.log('n', sprintf('%s: %s -- %s', variableName, strFirst, strLast))
            else
                irf.log('n', sprintf('%s: <empty>', variableName))
            end
        end
        
        
        
        function assert_Epoch(Epoch)
        % Assert that variable is an "zVar Epoch-like" variable.
        
            if ~iscolumn(Epoch)
                error('BICAS:dm_utils:Assertion:IllegalArgument', 'Argument is not a column vector')   % Right ID?                
            elseif ~isa(Epoch, 'int64')
                error('BICAS:dm_utils:Assertion:IllegalArgument', 'Argument has the wrong class.')   % Right ID?
            end
        end

        
        
        function assert_ACQUISITION_TIME(ACQUISITION_TIME)
        % Assert that variable is an "zVar ACQUISITION_TIME-like" variable.
        
            if ~isa(ACQUISITION_TIME, 'uint32')
                error('BICAS:dm_utils:Assertion:IllegalArgument', 'ACQUISITION_TIME is not uint32.')
            elseif ndims(ACQUISITION_TIME) ~= 2
                error('BICAS:dm_utils:Assertion:IllegalArgument', 'ACQUISITION_TIME is not 2D.')
            elseif size(ACQUISITION_TIME, 2) ~= 2
                error('BICAS:dm_utils:Assertion:IllegalArgument', 'ACQUISITION_TIME does not have two columns.')
            elseif any(ACQUISITION_TIME(:, 1) < 0)
                error('BICAS:dm_utils:Assertion:IllegalArgument', 'ACQUISITION_TIME has negative number of integer seconds.')
            elseif any(65536 <= ACQUISITION_TIME(:, 2))    % Does not need to check for negative values due to uint32.
                error('BICAS:dm_utils:Assertion:IllegalArgument', 'ACQUISITION_TIME subseconds out of range.')
            end
        end
        
        
        
        function assert_unvaried_N_rows(s)
        % Assert that all NUMERIC fields in a structure have the same number of rows.
        %
        % Useful since in data_manager, much code assumes that struct fields represent CDF zVar records which should
        % have the same number of rows.
        %
        % s : A struct to be tested.
            
            % PROPOSAL: Better name.
            %   Ex: _equal_rows, _equal_N_rows, _same_N_rows, _equal_nbr_of_rows
            
            fieldNamesList = fieldnames(s);
            nRows = [];
            for i = 1:length(fieldNamesList)
                fn = fieldNamesList{i};
                
                if isnumeric(s.(fn))
                    nRows(end+1) = size(s.(fn), 1);
                end
            end
            if length(unique(nRows)) > 1    % NOTE: length==0 valid for struct containing zero numeric fields.
                error('BICAS:dm_utils:Assertion', 'Numeric fields in struct do not have the same number of rows (likely corresponding to CDF zVar records).')
            end
        end
        
    end   % Static
    
    
    
end

