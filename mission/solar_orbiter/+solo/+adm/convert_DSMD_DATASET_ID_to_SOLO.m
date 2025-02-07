%
% Change all DATA_SET_IDs ROC-SGSE-->SOLO.
%
% NOTE: Requires DSMD.datasetId to be mutable.
%
% Author: Erik P G Johansson, IRF, Uppsala, Sweden
% First created 2020-05-27.
%
function DsmdArray = convert_DSMD_DATASET_ID_to_SOLO(DsmdArray)

    for i = 1:numel(DsmdArray)
        DsmdArray(i).datasetId = ...
            solo.adm.convert_DATASET_ID_to_SOLO(DsmdArray(i).datasetId);
    end
end
