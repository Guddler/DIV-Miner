/*
 * miner.prg by Mart
 * (c)2023 Nightweave
 *
 * Original assets from:
 * https://www.spriters-resource.com/zx_spectrum/manicminer/sheet/113060
 */

PROGRAM miner;

CONST
    STATE_NONE  = 0;
    STATE_WALK  = 1;
    STATE_JUMP  = 2;
    STATE_LEFT  = 3;
    STATE_RIGHT = 4;
    STATE_FALL  = 5;

    DIR_LEFT    = 1;
    DIR_RIGHT   = 0;

    //SCALE       = 1;
    ANIM_SPEED  = 2;

    _DEBUG      = 1;

GLOBAL
    s_width = 320;
    s_height = 240;
    STRUCT keys_pressed
        left;
        right;
        jump;
    END

    level = 1;
    lmap;
    hmap;

LOCAL
    //string s_size;
    anim;
    cur_dir;
    new_dir;

BEGIN
    file = load_fpg("/Users/mart/Dev/DIV-Miner/miner.fpg");
    //set_mode(640480);
    set_mode(320240);

    show_level();
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
    tid;
    speed;
    jump_height = 0;
    jump_speed = 1;
    jump_max = 16;
    WILLY_STATE = STATE_NONE;
    JUMP_STATE = STATE_NONE;

    string dtxt;
    int did;

begin
    // X and Y are the centre point
    speed = 1;
    x = 100;
    y = s_height - (9 + 8); // 8 for the bottom block + 8 for half willy's height
    graph = 1;
    //size = 100 * SCALE;

    cur_dir = DIR_RIGHT;

    loop
        anim++;
        delete_text(tid);
        delete_text(did);

        tid = write(0, 0, 30, 3, itoa(WILLY_STATE));

        // Holding both keys causes strage behaviour so block it
        if ((willy_state != state_jump && willy_state != state_fall)
            && keys_pressed.right && keys_pressed.left)
            frame;
            continue;
        end

        // Input handling
        if (keys_pressed.jump && (WILLY_STATE != STATE_JUMP && WILLY_STATE != STATE_FALL))
            //jump_speed -= gravity;
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
            if (WILLY_STATE != STATE_JUMP && WILLY_STATE != STATE_FALL)
                WILLY_STATE = STATE_NONE;
                if (keys_pressed.right && x + speed < (s_Width - 10))
                    x += speed;
                    new_dir = DIR_RIGHT;
                    willy_state = STATE_WALK;
                end

                if (keys_pressed.left && x - speed > 10)
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
                do_anim(1, 4);
                if (map_get_pixel(file, hmap, x, y + 8) == 0)
                    WILLY_STATE = STATE_FALL;
                end
            end

            case STATE_FALL :
                tid = write(0, 0, 20, 3, "State: FALL");
                y += jump_speed;
                jump_height -= jump_speed;
                if (JUMP_STATE == STATE_LEFT OR JUMP_STATE == STATE_RIGHT)
                    switch (JUMP_STATE)
                        case STATE_LEFT :
                            if (x - speed > 10) x -= speed; end
                        end
                        case STATE_RIGHT :
                            if (x + speed < (s_width - 10)) x += speed; end
                        end
                    end
                    do_anim(1, 4);
                end
                if (map_get_pixel(file, hmap, x, y + 8) == 255)
                    jump_height = 0;
                    WILLY_STATE = STATE_NONE;
                    JUMP_STATE = STATE_NONE;
                end
            end

            case STATE_JUMP : //, STATE_FALL :
                tid = write(0, 0, 20, 3, "State: JUMP");
                y -= jump_speed;
                jump_height += jump_speed;

                if (JUMP_STATE == STATE_LEFT OR JUMP_STATE == STATE_RIGHT)
                    switch (JUMP_STATE)
                        case STATE_LEFT :
                            if (x - speed > 10) x -= speed; end
                        end
                        case STATE_RIGHT :
                            if (x + speed < (s_width - 10)) x += speed; end
                        end
                    end
                    do_anim(1, 4);
                end
                if (jump_height > jump_max && WILLY_STATE == STATE_JUMP)
                    WILLY_STATE = STATE_FALL;
                end

            end

            case STATE_NONE :
                tid = write(0, 0, 20, 3, "State: NONE");
            end
        end

        if (_DEBUG == 0)
            delete_text(tid);
        end

        dtxt = "X: " + itoa(x) + " Y: " + itoa(y + 8) + " C: " +
            itoa(map_get_pixel(file, hmap, x, y + 8)) + " JH: " + itoa(jump_height);
        did = write(0, 0, 30, 3, dtxt);
        if (WILLY_STATE == STATE_JUMP || WILLY_STATE == STATE_FALL)
            frame(75);
        else
            frame;
        end
    end

end

process show_level()
private
    level_offset;
begin
    level_offset = (level - 1) * 2;
    // level map
    lmap = 500 + level_offset;
    // hardness map
    hmap = 501 + level_offset;
    xput(file, lmap, s_width / 2, s_height / 2, 0, 100, 0, 0);
    loop
        frame;
    end
end

function do_anim(min, max)
begin
    if (father.anim % ANIM_SPEED == 0)
        father.graph += 1;
        if (father.graph > max) father.graph = min; end
        if (father.cur_dir != father.new_dir)
            father.cur_dir = father.new_dir;
            father.flags = father.cur_dir;
        end
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
