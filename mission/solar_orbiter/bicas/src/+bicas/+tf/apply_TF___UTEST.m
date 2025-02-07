%
% matlab.unittest automatic test code for bicas.tf.apply_TF().
%
%
% Author: Erik P G Johansson, Uppsala, Sweden
% First created 2021-08-10
%
classdef apply_TF___UTEST < matlab.unittest.TestCase



    properties(TestParameter)
        METHOD = {'FFT', 'kernel'}
    end



    properties (Constant)
        NON_FV_SPLIT_SETTINGS = struct(...
            'snfEnabled',          false, ...
            'snfSubseqMinSamples', 1 ...
        )
    end



    %##############
    %##############
    % TEST METHODS
    %##############
    %##############
    methods(Test)



        % Enable RE-trending without DE-trending. ==> Error
        %
        function test_Illegal_detrending(testCase, METHOD)

            N  = 100;
            dt = 0.1;
            y1 = 5 * ones(N, 1);
            tf = @(omegaRps) (29);

            testCase.verifyError(...
                @() (bicas.tf.apply_TF(...
                    dt, y1, tf, ...
                    bicas.tf.apply_TF___UTEST.NON_FV_SPLIT_SETTINGS, ...
                    'method',             METHOD, ...
                    'detrendingDegreeOf', -10, ...
                    'retrendingEnabled',    1 ...   % Should be bool/logical.
                )), ...
                ?MException)
        end



        % Zero-order detrending. Constant signal ==> Output=0
        %
        function test_detrending0(testCase, METHOD)

            N  = 100;
            dt = 0.1;
            y1 = 5 * ones(N, 1);
            tf = @(omegaRps) (29);

            [y2, D] = bicas.tf.apply_TF(...
                dt, y1, tf, ...
                bicas.tf.apply_TF___UTEST.NON_FV_SPLIT_SETTINGS, ...
                'method',                     METHOD, ...
                'detrendingDegreeOf',         0, ...
                'retrendingEnabled',          false, ...
                'tfHighFreqLimitFraction',    Inf ...
            );

            % All three tests: No tolerance works on irony but fails in GitHub CI.
            testCase.verifyEqual(numel(D.y1ModifCa), 1)
            testCase.verifyEqual(D.y1ModifCa{1}, 0*y1, 'AbsTol', 1e-14)
            testCase.verifyEqual(D.y2ModifCa{1}, 0*y1, 'AbsTol', 1e-13)
            testCase.verifyEqual(y2,             0*y1, 'AbsTol', 1e-13)
        end



        % Test one signal with different parts being removed depending of degree
        % of detrending, and re-trending enabled/disabled.
        %
        function test_detrending_parts(testCase, METHOD)

            N  = 100;
            dt = 0.1;
            x  = linspace(-1, 1, N)';   % "Normalized" time.

            A  = 5;
            B  = 2;
            % NOTE: y1_0 removed exactly by zero-order de-trending.
            y1_0 = A * ones(size(x));
            y1_1 = B * x;
            y1   = y1_0 + y1_1;
            tf   = @(omegaRps) (29);   % Constant TF.



            % No detrending
            [y2, D] = bicas.tf.apply_TF(...
                dt, y1, tf, ...
                bicas.tf.apply_TF___UTEST.NON_FV_SPLIT_SETTINGS, ...
                'method',                  METHOD, ...
                'detrendingDegreeOf',      -1, ...
                'retrendingEnabled',       false, ...
                'tfHighFreqLimitFraction', Inf ...
            );
            testCase.verifyEqual(D.y1ModifCa{1}, y1,    'AbsTol', 1e-14)
            testCase.verifyEqual(D.y2ModifCa{1}, y1*29, 'AbsTol', 1e-13)
            testCase.verifyEqual(y2,  y1*29, 'AbsTol', 1e-13)



            % Zero order detrending.
            [y2, D] = bicas.tf.apply_TF(...
                dt, y1, tf, ...
                bicas.tf.apply_TF___UTEST.NON_FV_SPLIT_SETTINGS, ...
                'method',                  METHOD, ...
                'detrendingDegreeOf',      0, ...
                'retrendingEnabled',       false, ...
                'tfHighFreqLimitFraction', Inf ...
            );

            testCase.verifyEqual(D.y1ModifCa{1}, y1_1,    'AbsTol', 1e-14)
            testCase.verifyEqual(D.y2ModifCa{1}, y1_1*29, 'AbsTol', 1e-13)
            testCase.verifyEqual(y2,  y1_1*29, 'AbsTol', 1e-13)



            % Second order detrending.
            [y2, D] = bicas.tf.apply_TF(...
                dt, y1, tf, ...
                bicas.tf.apply_TF___UTEST.NON_FV_SPLIT_SETTINGS, ...
                'method',                  METHOD, ...
                'detrendingDegreeOf',      2, ...
                'retrendingEnabled',       false, ...
                'tfHighFreqLimitFraction', Inf ...
            );

            testCase.verifyEqual(D.y1ModifCa{1}, zeros(size(y1_1)), 'AbsTol', 1e-14)
            testCase.verifyEqual(D.y2ModifCa{1}, zeros(size(y1_1)), 'AbsTol', 1e-13)
            testCase.verifyEqual(y2,  zeros(size(y1_1)), 'AbsTol', 1e-13)



            % Second order detrending + RE-trending
            [y2, D] = bicas.tf.apply_TF(...
                dt, y1, tf, ...
                bicas.tf.apply_TF___UTEST.NON_FV_SPLIT_SETTINGS, ...
                'method',                  METHOD, ...
                'detrendingDegreeOf',      2, ...
                'retrendingEnabled',       true, ...
                'tfHighFreqLimitFraction', Inf ...
            );

            testCase.verifyEqual(D.y1ModifCa{1}, zeros(size(y1_1)), 'AbsTol', 1e-14)
            testCase.verifyEqual(D.y2ModifCa{1}, zeros(size(y1_1)), 'AbsTol', 1e-13)
            testCase.verifyEqual(y2,  29*y1,             'AbsTol', 1e-13)
        end



        % Test (Nyquist) frequency cutoff.
        %
        function test_Freq_cutoff(testCase)
            %close all

            N  = 2^7;
            dt = 0.1;
            t  = [0:N-1]' * dt;

            nyquistOmegaRps = pi/dt;
            omega1 = nyquistOmegaRps*0.25;   % Survives   tfHighFreqLimitFraction.
            omega2 = nyquistOmegaRps*0.50;   % Removed by tfHighFreqLimitFraction.
            y1_1   = sin(omega1*t);
            y1_2   = sin(omega2*t);
            y1     = y1_1 + y1_2;

            tf     = bicas.tf.utest_utils.get_tf_delay(1*dt);

            if 1

                [y2, D] = bicas.tf.apply_TF(...
                    dt, y1, tf, ...
                    bicas.tf.apply_TF___UTEST.NON_FV_SPLIT_SETTINGS, ...
                    'method',                 'FFT', ...
                    'detrendingDegreeOf',     -1, ...
                    'retrendingEnabled',      false, ...
                    'tfHighFreqLimitFraction', 0.4 ...
                );

                y2_exp = circshift(y1_1, 1);   % Requires FFT method.
                %bicas.tf.apply_TF___UTEST.plot_test(y1, y2, y2_exp)

                testCase.verifyEqual(abs(D.tfModif(omega1)), 1)
                testCase.verifyEqual(abs(D.tfModif(omega2)), 0)
                testCase.verifyEqual(y2, y2_exp, 'AbsTol', 1e-13)
            end
        end



        function test_SNF(testCase)

            % ====================
            % Construct test cases
            % ====================
            C = 3;
            TEST_DATA_CA = { ...
                struct( ...
                    'snfSubseqMinSamples', 1, ...
                    'iFvArray',  [], ...
                    'y1ModifCa', {{[1:100]'}}, ...
                    'y2',        [1:100]' * C ...
                ), ...
                struct( ...
                    'snfSubseqMinSamples', 1, ...
                    'iFvArray',  [11], ...
                    'y1ModifCa', {{[1:10]', [12:100]'}'}, ...
                    'y2',        [1:10, NaN, 12:100]' * C ...
                ), ...
                struct( ...
                    'snfSubseqMinSamples', 1, ...
                    'iFvArray',  [1, 11], ...
                    'y1ModifCa', {{[2:10]', [12:100]'}'}, ...
                    'y2',        [NaN, 2:10, NaN, 12:100]' * C ...
                ), ...
                struct( ...
                    'snfSubseqMinSamples', 1, ...
                    'iFvArray',  [91, 100], ...
                    'y1ModifCa', {{[1:90]', [92:99]'}'}, ...
                    'y2',        [1:90, NaN, 92:99, NaN]' * C ...
                ), ...
                ... % No splitting. Subsequence too short.
                struct( ...
                    'snfSubseqMinSamples', 1000, ...
                    'iFvArray',  [], ...
                    'y1ModifCa', {{[]}}, ...
                    'y2',        [NaN(1,100)]' * C ...
                ), ...
                ... % Splitting. 1/2 subsequences is too short.
                struct( ...
                    'snfSubseqMinSamples', 20, ...
                    'iFvArray',  [1, 11], ...
                    'y1ModifCa', {{[], [12:100]'}'}, ...
                    'y2',        [NaN(1,11), 12:100]' * C ...
                ), ...
            };
            for i = 1:numel(TEST_DATA_CA)
                Td = TEST_DATA_CA{i};
                Td.y2ModifCa = cell(1,0);
                for j = 1:numel(Td.y1ModifCa)
                    Td.y2ModifCa{j, 1} = Td.y1ModifCa{j} * C;
                end
                TEST_DATA_CA{i} = Td;
            end

            % =========
            % Run tests
            % =========
            for i = 1:numel(TEST_DATA_CA)
                Td = TEST_DATA_CA{i};

                dt = 0.1;
                y1 = [1:100]';
                tf = bicas.tf.utest_utils.get_tf_constant(C, C);

                y1(Td.iFvArray) = NaN;

                [y2, D] = bicas.tf.apply_TF(...
                    dt, y1, tf, ...
                    'method',              'kernel', ...
                    'detrendingDegreeOf',  -1, ...
                    'retrendingEnabled',   false, ...
                    'snfEnabled',          true, ...
                    'snfSubseqMinSamples', Td.snfSubseqMinSamples ...
                );

                testCase.verifyEqual(D.y1ModifCa, Td.y1ModifCa, 'RelTol', 1e-14)
                testCase.verifyEqual(D.y2ModifCa, Td.y2ModifCa, 'RelTol', 1e-14)
                testCase.verifyEqual(y2,          Td.y2,        'RelTol', 1e-14)
            end

        end



    end    % methods(Test)



    %########################
    %########################
    % PRIVATE STATIC METHODS
    %########################
    %########################
    methods(Static, Access=private)



        function plot_test(y1, y2_act, y2_exp)
            figure
            plot([y1, y2_act, y2_exp+0.01], '*-')
            legend({'y1', 'y2_{act}', 'y2_{exp}'})
        end



    end    % methods(Static, Access=private)



end
