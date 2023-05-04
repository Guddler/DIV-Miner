/*
 * test.prg by Mart
 * (c) 2023 Nightweave
 */

PROGRAM test;

CONST
    STATE_NONE  = 0;
    STATE_WALK  = 1;
    STATE_JUMP  = 2;
    STATE_LEFT  = 3;
    STATE_RIGHT = 4;
    STATE_FALL  = 5;

    DIR_LEFT    = 1;
    DIR_RIGHT   = 0;

    SCALE = 2;
    ANIM_SPEED = 2;

GLOBAL
    s_width = 320 * SCALE;
    s_height = 240 * SCALE;
    STRUCT keys_pressed
        left;
        right;
        jump;
    END

LOCAL
    string s_size;

BEGIN
    load_fpg("miner.fpg");
    set_mode(640480);
    //set_mode(320240);

    // Key handler
    do_keys();
    // Player
    player();

    while (!key(_esc))
        frame;
    end
    exit("", 0);
END

process player()
private
    cur_dir = DIR_RIGHT;
    new_dir;
    tid;
    speed;
    anim;
    jump_speed = 0;
    gravity = 10;
    WILLY_STATE = STATE_NONE;
    JUMP_STATE = STATE_NONE;
begin
    speed = SCALE;
    x = 100;
    y = s_height - (8 + (16 * scale));
    graph = 1;
    size = 100 * SCALE;

    loop
        anim++;
        delete_text(tid);

        tid = write(0, 0, 30, 3, itoa(WILLY_STATE));

        // Holding both keys causes strage behaviour so block it
        if (willy_state != state_jump && keys_pressed.right && keys_pressed.left)
            frame;
            continue;
        end

        // Input handling
        if (keys_pressed.jump && WILLY_STATE != STATE_JUMP)
            jump_speed -= gravity;
            WILLY_STATE = STATE_JUMP;
            JUMP_STATE = STATE_NONE;
            // This just captures the state of left or right keys at time of jump
            // We do not change direction mid-air
            if (keys_pressed.left)
                JUMP_STATE = STATE_LEFT;
            end
            if (keys_pressed.right)
                JUMP_STATE = STATE_RIGHT;
            end
        else
            if (WILLY_STATE != STATE_JUMP)
                WILLY_STATE = STATE_NONE;
                if (keys_pressed.right && x + speed < (s_Width - (10 * SCALE)))
                    x += speed;
                    new_dir = DIR_RIGHT;
                    willy_state = STATE_WALK;
                end

                if (keys_pressed.left && x - speed > (10 * SCALE))
                    x -= speed;
                    new_dir = DIR_LEFT;
                    willy_state = STATE_WALK;
                end
            end
        end

        // Player logic
        switch (WILLY_STATE)
            case STATE_WALK :
                tid = write(0, 0, 20, 3, "State: WALK");
                if (anim % ANIM_SPEED == 0)
                    graph += 1;
                    if (graph > 4) graph = 1; end
                    if (cur_dir != new_dir)
                        cur_dir = new_dir;
                        flags = cur_dir;
                    end
                end
            end
            case STATE_JUMP :
                tid = write(0, 0, 20, 3, "State: JUMP");
                y = y + jump_speed;
                jump_speed += 1;
                switch (JUMP_STATE)
                    case STATE_LEFT :
                        if (x - speed > (10 * SCALE)) x -= speed; end
                    end
                    case STATE_RIGHT :
                        if (x + speed < (s_width - (10 * scale))) x += speed; end
                    end
                end
                if (JUMP_STATE == STATE_LEFT OR JUMP_STATE == STATE_RIGHT)
                    if (anim % ANIM_SPEED == 0)
                        graph += 1;
                        if (graph > 4) graph = 1; end
                        if (cur_dir != new_dir)
                            cur_dir = new_dir;
                            flags = cur_dir;
                        end
                    end
                end
                if (jump_speed > gravity)
                    jump_speed = 0;
                    WILLY_STATE = STATE_NONE;
                    JUMP_STATE = STATE_NONE;
                end
            end
            case STATE_NONE :
                tid = write(0, 0, 20, 3, "State: NONE");
            end
        end

        frame;
    end

end

// Check and set every key once per frame
process do_keys()
begin
    loop
        if (key(_left) or key(_o))
            keys_pressed.left = TRUE;
        else
            keys_pressed.left = FALSE;
        end

        if (key(_right) or key(_p))
            keys_pressed.right = TRUE;
        else
            keys_pressed.right = FALSE;
        end

        if (key(_space))
            keys_pressed.jump = TRUE;
        else
            keys_pressed.jump = FALSE;
        end

        frame;
    end
end

