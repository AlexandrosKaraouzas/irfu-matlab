%
% Collection of constants related to validating BICAS (output) master CDFs.
%
%
% Author: Erik P G Johansson, IRF, Uppsala, Sweden
% First created 2020-11-12
%
classdef const
    % PROPOSAL: Collect functions too.
    

    
    %#####################
    %#####################
    % INSTANCE PROPERTIES
    %#####################
    %#####################
    properties(Constant)
        % Docs specifies spelling "Acknowledgment", but ISTP specifies spelling
        % "Acknowledgement" ("-ledg" vs "-ledge").
        %
        % NOTE: Incomplete list of mandatory global attributes (too long).
        % NOTE: Most of global attributes names have just been copied from
        %       de facto datasets. There is still value in that it checks that
        %       the same global attributes are used everywhere.
        EXACT_L2_GLOBAL_ATTRIBUTES = {...
            'ACCESS_FORMAT', 'ACCESS_URL', 'Acknowledgement', ...
            'Dataset_ID', 'Data_type', ...
            'Data_version', 'Descriptor', 'Discipline', ...
            'File_naming_convention', 'Generated_by', ...
            'HTTP_LINK', 'Instrument_type', 'LEVEL', 'LINK_TEXT', ...
            'APPLICABLE', 'CALIBRATION_TABLE', 'CALIBRATION_VERSION', ...
            'CAL_ENTITY_AFFILIATION', 'CAL_ENTITY_NAME', ...
            'CAL_EQUIPMENT', 'CAVEATS', 'Data_product', 'Datetime', ...
            'File_ID', 'Free_field', 'Generation_date', ...
            'Job_ID', 'LINK_TITLE', 'Logical_file_id', 'Logical_source', ...
            'Logical_source_description', 'MODS', ...
            'Mission_group', 'OBS_ID', 'PI_affiliation', 'PI_name', ...
            'Parent_version', 'Parents', 'Pipeline_name', ...
            'Pipeline_version', 'Project', 'Provider', 'REFERENCE', ...
            'Rules_of_use', 'SKELETON_PARENT', 'SOOP_TYPE', ...
            'SPECTRAL_RANGE_MAX', 'SPECTRAL_RANGE_MIN', 'SPICE_KERNELS', ...
            'Skeleton_version', 'Software_name', 'Software_version', 'Source_name', ...
            'TARGET_CLASS', 'TARGET_NAME', 'TARGET_REGION', 'TEXT', ...
            'TEXT_supplement_1', 'TIME_MAX', ...
            'TIME_MIN', 'Validate'};
        
        MANDATORY_L2_ZV_NAMES = {...
            'VDC', 'EDC', 'EAC', ...
            'VDC_LABEL', 'EDC_LABEL', 'EAC_LABEL', ...
            'IBIAS1', 'IBIAS2', 'IBIAS3', 'DELTA_PLUS_MINUS', ...
            'Epoch', ...
            'QUALITY_BITMASK', 'L2_QUALITY_BITMASK', 'QUALITY_FLAG', ...
            'SAMPLING_RATE', 'SYNCHRO_FLAG'};
        
        % ACQUISITON_TIME* temporary. Should be abolished.
        SOMETIMES_L2_ZV_NAMES = {...
            'ACQUISITION_TIME', 'ACQUISITION_TIME_LABEL', ...
            'ACQUISITION_TIME_UNITS', 'BW'};
        
        % NOTE: Does not seem to be very many truly mandatory attribute fields.
        % 2020-03-25: Values are empirical.
        % NOTE: All but Epoch require DEPEND_0.
        % NOTE: LABLAXIS and LABL_PTR_1 are mutualy exclusive.
        MANDATORY_ZV_ATTRIBUTES = {'FIELDNAM', 'CATDESC', 'VAR_TYPE'};
        SOMETIMES_ZV_ATTRIBUTES = {...
            'DISPLAY_TYPE', 'VALIDMIN', 'VALIDMAX', 'SCALEMIN', 'SCALEMAX', ...
            'FILLVAL', 'LABLAXIS', ...
            'UNITS', 'SCALETYP', 'MONOTON', 'TIME_BASE', 'TIME_SCALE', ...
            'REFERENCE_POSITION', 'Resolution', ...
            'Bin_location', 'VAR_NOTES', 'DEPEND_0', 'FORMAT', ...
            'LABL_PTR_1', 'UNIT_PTR', 'UCD', ...
            'DELTA_PLUS_VAR', 'DELTA_MINUS_VAR', ...
            'SI_CONVERSION'};
        
    end
    
    
end
