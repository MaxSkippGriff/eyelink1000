% Matlab code for EyeLink1000 Plus
%

try
    fprintf('Experiment starting\n\n\t');
    dummymode = 1; % set to 1 to initialize in dummymode

    % STEP 1
    % Open a graphics window on the main screen
    screenNumber = max(Screen('Screens'));
    [window, wRect] = Screen('OpenWindow', screenNumber);

    % STEP 2
    % Provide Eyelink with details about the graphics environment
    % and perform some initializations. The information is returned
    % in a structure that also contains useful defaults
    % and control codes (e.g. tracker state bit and Eyelink key values).
    el = EyelinkInitDefaults(window);

    % STEP 3
    % Initialization of the connection with the Eyelink Gazetracker.
    % exit program if this fails.
    if ~EyelinkInit(dummymode)
        fprintf('Eyelink Init aborted.\n');
        cleanup; % cleanup function
        return;
    end

    [v, vs] = Eyelink('GetTrackerVersion');
    fprintf('Running experiment on a ''%s'' tracker.\n', vs);

    % STEP 4
    % Do setup and calibrate the eye tracker
    EyelinkDoTrackerSetup(el);

    % do a final check of calibration using driftcorrection
    % You have to hit esc before return.
    EyelinkDoDriftCorrection(el);

    % Create a window and set some properties
    screenNumber = max(Screen('Screens'));
    window = Screen('OpenWindow', screenNumber);
    screenRect = Screen('Rect', window);
    Screen('TextSize', window, 24);

    % Load the videos
    videos = cell(1, 20);
    for i = 1:20
        videoFile = sprintf('videoz/%d.mp4', i);
        videos{i} = VideoReader(videoFile);
    end

    % Set the sliding scale properties
    sliderLength = screenRect(3) - 200;
    sliderRect = [0 0 sliderLength 10];
    sliderColor = [0 0 0];
    sliderPosition = sliderLength / 2;
    sliderStep = 10;

    % Show the videos
    for i = 1:20
        % Show fixation cross
        DrawFormattedText(window, '+', 'center', 'center', [255 255 255]);
        Screen('Flip', window);
        WaitSecs(1);

        % Start recording
        Eyelink('StartRecording');

        % Show the video
        video = videos{i};
        while hasFrame(video)
            frame = readFrame(video);
            Screen('DrawTexture', window, Screen('MakeTexture', window, frame));
            Screen('FillRect', window, sliderColor, CenterRectOnPoint(sliderRect, screenRect(3) / 2, screenRect(4) - 50));
            DrawFormattedText(window, 'low trust', sliderRect(1), sliderRect(2) + 25, [255 255 255]);
            DrawFormattedText(window, 'high trust', sliderRect(3) - 90, sliderRect(2) + 25, [255 255 255]);
            Screen('FillRect', window, [255 0 0], [sliderPosition - 2 screenRect(4) - 55 sliderPosition + 2 screenRect(4) - 45]);
            Screen('Flip', window);

            % Check for keyboard input
            [keyIsDown, seconds, keyCode] = KbCheck;
            if keyIsDown
                if keyCode(KbName('RightArrow'))
                        scalePosition = min(scalePosition + scaleStep, screenRect(3));
                    elseif keyCode(KbName('LeftArrow'))
                        scalePosition = max(scalePosition - scaleStep, 0);
                    end
                end
            end

            % Stop recording and send data to EDF file
            Eyelink('StopRecording');
            Eyelink('Message', sprintf('VIDEO_%d_START', i));
            Eyelink('Message', sprintf('VIDEO_%d_END', i));
            Eyelink('Message', sprintf('SCALE_POSITION_%d', scalePosition));
        end

        % Close the window and the EDF file
        Screen('CloseAll');
        Eyelink('CloseFile');
        Eyelink('Shutdown');
        % mark image removal time in data file
        Eyelink('Message', 'ENDTIME');
        WaitSecs(0.5);
        Eyelink('Message', 'TRIAL_END');

        % STEP 8
        % finish up: stop recording eye-movements,
        % close graphics window, close data file and shut down tracker
        Eyelink('StopRecording');
        Eyelink('CloseFile');
        cleanup;

catch

end
