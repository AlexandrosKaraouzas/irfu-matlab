% IRF_INDENTATIONS ensures uniform 2 space indentations is used in all
% applicable irfu-matlab .m files as per our CONTRIBUTING.md guidelines
%
% 	IRF_TEMPLATE opens and in applicable cases re-writes all files using
% 	Matlab's own smartIndentContents(). For this to work one should first
%   set appropriate "Tab size = 2" & "Indent size = 2" in the Matlab editor
% 	found under "Matlab" -> "Preferences" -> "Editor/Debugger" -> "Tab".
%
% Note: SolarOrbiter specific code ("mission/solo/") and externally
%       contributed code ("contrib/") is excluded from this 2 space
%       recommendation.
%
% 	See also smartIndentContents, <a href="matlab:web('https://github.com/irfu/irfu-matlab/blob/master/.github/CONTRIBUTING.md')">.github/CONTRIBUTING.md</a>

irfPath = irf('path'); % irf root path

irfDirectories = {...
  '.', ...  % irf root path
  '@dataobj', ...
  '+local', ...
  '+lp', ...
  '+maarble', ...
  '+model', ...
  '+whamp', ...
  'irf', ...
  ['irf'     filesep '+irf'], ...
  ['mission' filesep 'cluster'], ...
  ['mission' filesep 'cluster' filesep 'c_ri'], ...
  ['mission' filesep 'cluster' filesep 'caa'], ...
  ['mission' filesep 'cluster' filesep 'caa' filesep '@ClusterDB'], ...
  ['mission' filesep 'cluster' filesep 'caa' filesep '@ClusterProc'], ...
  ['mission' filesep 'mms'], ...
  ['mission' filesep 'mms' filesep '+mms'], ...
  ['mission' filesep 'mms' filesep 'cal'], ...
  ['mission' filesep 'mms' filesep 'mms_testFunctions'], ...
  ['mission' filesep 'rosetta'], ...
  ['mission' filesep 'themis'], ...
  ['mission' filesep 'thor'], ...
  ['mission' filesep 'thor' filesep 'orbit_coverage'], ...
  ['mission' filesep 'thor' filesep 'plots'], ...
  'plots', ...
  ['plots'   filesep 'mms']
  };

for iPath = 1:numel(irfDirectories)
  pathToCheck = [irfPath, filesep, irfDirectories{iPath}];
  mFiles = dir([pathToCheck, filesep, '*.m']);
  for iFile = 1:length(mFiles)
    theDocument = matlab.desktop.editor.openDocument(fullfile(mFiles(iFile).folder, mFiles(iFile).name));
    smartIndentContents(theDocument);
    save(theDocument);
    close(theDocument);
  end
end

