IMPORT util
IMPORT os

CONSTANT SHOW_DELAY = 750
CONSTANT INBETWEEN_DELAY = 250
CONSTANT TOOLONG_DELAY = 2000

DEFINE m_game DYNAMIC ARRAY OF SMALLINT
DEFINE m_game_idx INTEGER

MAIN
    DEFER INTERRUPT
    DEFER QUIT
    CALL util.Math.srand()
    
    CALL ui.Interface.loadStyles("simonero.4st")
    CLOSE WINDOW SCREEN
    OPEN WINDOW w WITH FORM "simonero"

    CALL simonero()
END MAIN

FUNCTION simonero()
    DISPLAY "top_left" TO top_left
    DISPLAY "top_right" TO top_right
    DISPLAY "middle_left" TO middle_left
    DISPLAY "middle_right" TO middle_right
    DISPLAY "bottom_left" TO bottom_left
    DISPLAY "bottom_right" TO bottom_right

    WHILE TRUE
        MENU ""
            BEFORE MENU
                CALL pieces_active_set(DIALOG, FALSE)
                CALL DIALOG.setActionActive("last", m_game.getLength() > 0)

            ON ACTION start -- Start a new game
                CALL DIALOG.setActionActive("last", FALSE)
                CALL DIALOG.setActionActive("start", FALSE)
                CALL DIALOG.setActionActive("test", FALSE)
                CALL m_game.clear()
                CALL computer_turn()
                LET m_game_idx = 1
                CALL pieces_active_Set(DIALOG, TRUE)
                CALL start_timer()

            ON ACTION last -- Replay the last game
                CALL play_path()
                CALL FGL_WINMESSAGE("Simonero", SFMT("Last Game\nScore=%1", m_game.getLength() - 1), "info")

            ON ACTION test ATTRIBUTES(TEXT = "Test") -- Use to test pieces
                CALL play_piece(1)
                CALL play_piece(2)
                CALL play_piece(3)
                CALL play_piece(4)
                CALL play_piece(5)
                CALL play_piece(6)
                CALL play_sound(0)

            ON ACTION top_left
                IF NOT player_tap(DIALOG, 1) THEN
                    EXIT MENU
                END IF

            ON ACTION top_right
                IF NOT player_tap(DIALOG, 2) THEN
                    EXIT MENU
                END IF

            ON ACTION middle_left
                IF NOT player_tap(DIALOG, 6) THEN
                    EXIT MENU
                END IF

            ON ACTION middle_right
                IF NOT player_tap(DIALOG, 3) THEN
                    EXIT MENU
                END IF

            ON ACTION bottom_left
                IF NOT player_tap(DIALOG, 5) THEN
                    EXIT MENU
                END IF

            ON ACTION bottom_right
                IF NOT player_tap(DIALOG, 4) THEN
                    EXIT MENU
                END IF

            ON ACTION toolong ATTRIBUTES(DEFAULTVIEW = NO) -- Called by timer in web component to signify too slow
                EXIT MENU

            ON ACTION quit
                EXIT WHILE

        END MENU

        CALL play_sound(0)
        CALL FGL_WINMESSAGE("Simonero", SFMT("Game Over\nScore=%1", m_game.getLength() - 1), "stop")
    END WHILE
END FUNCTION

FUNCTION player_tap(d, player_tap)
    DEFINE d ui.Dialog
    DEFINE player_tap INTEGER

    CALL stop_timer()

    --Exit if wrong move
    IF m_game[m_game_idx] != player_tap THEN -- Wrong more
        RETURN FALSE
    END IF

    -- Correct move, animate
    CALL play_sound(player_tap)
    CALL play_piece(player_tap)
    LET m_game_idx = m_game_idx + 1

    -- Add a new move
    IF m_game_idx > m_game.getLength() THEN
        CALL pieces_active_set(d, FALSE)
        CALL computer_turn()
        LET m_game_idx = 1
        CALL pieces_active_set(d, TRUE)
    END IF

    CALL start_timer()
    RETURN TRUE
END FUNCTION

FUNCTION computer_turn()
    CALL small_sleep(INBETWEEN_DELAY)
    LET m_game[m_game.getLength() + 1] = util.Math.rand(6) + 1
    CALL play_path()
END FUNCTION

FUNCTION play_path()
    DEFINE i INTEGER

    CALL small_sleep(SHOW_DELAY)
    FOR i = 1 TO m_game.getLength()
        CALL play_piece(m_game[i])
        CALL small_sleep(INBETWEEN_DELAY)
    END FOR
END FUNCTION

FUNCTION play_piece(i)
    DEFINE i INTEGER
    DEFINE j INTEGER

    CALL play_sound(i)
    FOR j = 1 TO 2
        CASE i
            WHEN 1
                DISPLAY IIF(j = 1, "top_left_pressed", "top_left") TO top_left;
            WHEN 2
                DISPLAY IIF(j = 1, "top_right_pressed", "top_right") TO top_right;
            WHEN 3
                DISPLAY IIF(j = 1, "middle_right_pressed", "middle_right") TO middle_right;
            WHEN 4
                DISPLAY IIF(j = 1, "bottom_right_pressed", "bottom_right") TO bottom_right;
            WHEN 5
                DISPLAY IIF(j = 1, "bottom_left_pressed", "bottom_left") TO bottom_left;
            WHEN 6
                DISPLAY IIF(j = 1, "middle_left_pressed", "middle_left") TO middle_left;
        END CASE
        CALL ui.Interface.refresh()
        IF j = 1 THEN
            CALL small_sleep(SHOW_DELAY)
        END IF
    END FOR
END FUNCTION

FUNCTION play_sound(i)
    DEFINE i INTEGER
    DEFINE file_name STRING
    DEFINE uri STRING

    CASE i
        WHEN 1
            LET file_name = "E1.wav"
        WHEN 2
            LET file_name = "G1.wav"
        WHEN 3
            LET file_name = "C1.wav"
        WHEN 4
            LET file_name = "E2.wav"
        WHEN 5
            LET file_name = "G2.wav"
        WHEN 6
            LET file_name = "C2.wav"
        OTHERWISE
            LET file_name = "Tone_Cymbal.mp3"
    END CASE

    LET uri = ui.Interface.filenameToURI(os.Path.join(os.Path.pwd(), os.Path.join("../images", file_name)))
    CALL ui.Interface.frontCall("standard", "playsound", [uri, FALSE], [])
END FUNCTION

-- Use Hidden Web Component to trigger an action when user takes too long
FUNCTION start_timer()
    CALL ui.Interface.frontCall("webcomponent", "call", ["formonly.timer", "starttoolong", TOOLONG_DELAY], [])
END FUNCTION

FUNCTION stop_timer()
    CALL ui.Interface.frontCall("webcomponent", "call", ["formonly.timer", "cleartoolong", TOOLONG_DELAY], [])
END FUNCTION

FUNCTION pieces_active_set(d, active)
    DEFINE d ui.Dialog
    DEFINE active BOOLEAN

    CALL d.setActionActive("top_left", active)
    CALL d.setActionActive("top_right", active)
    CALL d.setActionActive("middle_right", active)
    CALL d.setActionActive("bottom_right", active)
    CALL d.setActionActive("bottom_left", active)
    CALL d.setActionActive("middle_left", active)
END FUNCTION

-- In continuing absence of SLEEP command that operates for less than a second
FUNCTION small_sleep(f)
    DEFINE f INTEGER
    DEFINE s STRING
    DEFINE in INTERVAL SECOND TO FRACTION(3)
    DEFINE ds, dn DATETIME YEAR TO FRACTION(3)

    IF f > 999 THEN
        LET f = 999
    END IF
    LET s = "0.", f USING "&&&"
    LET in = s
    LET ds = CURRENT YEAR TO FRACTION(3)
    WHILE TRUE
        LET dn = CURRENT YEAR TO FRACTION(3)
        IF (dn - ds) > in THEN
            EXIT WHILE
        END IF
    END WHILE
END FUNCTION
