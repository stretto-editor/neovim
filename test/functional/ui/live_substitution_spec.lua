-- Test the good behavior of the live action : substitution

local helpers = require('test.functional.helpers')
local Screen = require('test.functional.ui.screen')
local clear, feed, insert = helpers.clear, helpers.feed, helpers.insert
local execute, request, neq = helpers.execute, helpers.request, helpers.neq


describe('Live Substitution', function()
    local screen
    local curbuf

    local hl_colors = {
        NonText = Screen.colors.Blue,
        Question = Screen.colors.SeaGreen,
        String = Screen.colors.Fuchsia,
        Statement = Screen.colors.Brown,
        Special = Screen.colors.SlateBlue,
        Identifier = Screen.colors.DarkCyan
    }

    before_each(function()
        clear()
        execute("syntax on")
        execute("set livesub")
        screen = Screen.new(40, 40)  -- 40 lines of 40 char
        screen:attach()
        screen:set_default_attr_ignore( {{bold=true, foreground=hl_colors.NonText}} )
        screen:set_default_attr_ids({
            [1] = {foreground = hl_colors.String},
            [2] = {foreground = hl_colors.Statement, bold = true},
            [3] = {foreground = hl_colors.Special},
            [4] = {bold = true, foreground = hl_colors.Special},
            [5] = {foreground = hl_colors.Identifier},
            [6] = {bold = true},
            [7] = {underline = true, bold = true, foreground = hl_colors.Special},
            [8] = {foreground = hl_colors.Special, underline = true}
        })
        curbuf = request('vim_get_current_buffer')
    end)

    after_each(function()
        screen:detach()
    end)

    local function add_hl(...)
        return request('buffer_add_highlight', curbuf, ...)
    end

    local function clear_hl(...)
        return request('buffer_clear_highlight', curbuf, ...)
    end

    -- ----------------------------------------------------------------------
    -- simple tests
    -- ----------------------------------------------------------------------

    it('old behavior if :set nolivesub', function()
        insert([[
      these are some lines
      with colorful text (are)]])
        feed(':set nolivesub\n')
        feed(':%s/are/ARE')

        screen:expect([[
      these are some lines                    |
      with colorful text (are)                |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      :%s/are/ARE^                             |
    ]])

        feed('\27')     -- ESC
        feed(':%s/are/ARE\n')

        screen:expect([[
          these ARE some lines                    |
          ^with colorful text (ARE)                |
          ~                                       |
          ~                                       |
          ~                                       |
          ~                                       |
          ~                                       |
          ~                                       |
          ~                                       |
          ~                                       |
          ~                                       |
          ~                                       |
          ~                                       |
          ~                                       |
          ~                                       |
          ~                                       |
          ~                                       |
          ~                                       |
          ~                                       |
          ~                                       |
          ~                                       |
          ~                                       |
          ~                                       |
          ~                                       |
          ~                                       |
          ~                                       |
          ~                                       |
          ~                                       |
          ~                                       |
          ~                                       |
          ~                                       |
          ~                                       |
          ~                                       |
          ~                                       |
          ~                                       |
          ~                                       |
          ~                                       |
          ~                                       |
          ~                                       |
          :%s/are/ARE                             |
    ]])
    end)

    it('no split if :s', function()
        insert([[
      these are some lines
      with colorful text (are)]])
        feed(':s/are/ARE')

        screen:expect([[
      these are some lines                    |
      with colorful text (are)                |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      ~                                       |
      :s/are/ARE^                              |
    ]])
    end)

    it('split if :%s/are', function()
        insert([[
      these are some lines
      without colorful text (are)]])
        feed(':%s/are')

        screen:expect([[
        these {UNEXPECTED background = Screen.colors.Yellow:are} some lines                    |
        without colorful text ({UNEXPECTED background = Screen.colors.Yellow:are})             |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        {UNEXPECTED bold = true, reverse = true:[No Name] [+]                           }|
         [1]these {UNEXPECTED background = Screen.colors.Yellow:are} some lines                |
         [2]without colorful text ({UNEXPECTED background = Screen.colors.Yellow:are})         |
                                                |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        {UNEXPECTED reverse = true:[live_sub]                              }|
        :%s/are^                                 |
    ]])
    end)

    it('split if :%s/are/', function()
        insert([[
      these are some lines
      with colorful text (are)]])
        feed(':%s/are/')

        screen:expect([[
        these  some lines                       |
        with colorful text ()                   |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        {UNEXPECTED bold = true, reverse = true:[No Name] [+]                           }|
         [1]these  some lines                   |
         [2]with colorful text ()               |
                                                |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        {UNEXPECTED reverse = true:[live_sub]                              }|
        :%s/are/^                                |
    ]])
    end)


    it('split if :%s/are/to', function()
        insert([[
      these are some lines
      with colorful text (are)]])
        feed(':%s/are/to')

        screen:expect([[
        these to some lines                     |
        with colorful text (to)                 |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        {UNEXPECTED bold = true, reverse = true:[No Name] [+]                           }|
         [1]these to some lines                 |
         [2]with colorful text (to)             |
                                                |
        ~                                       |
        ~                                       |
        ~                                       |
        ~                                       |
        {UNEXPECTED reverse = true:[live_sub]                              }|
        :%s/are/to^                              |
   ]])
    end)

    -- ----------------------------------------------------------------------
    -- complex tests
    -- ----------------------------------------------------------------------

    it('scenario', function()
        insert([[
      these are some lines
      with colorful text (are)]])

        feed('gg')
        feed('2yy')
        feed('10000p')

        feed(':%s/are/ARE')     -- simple sub, aborted

        screen:expect([[
            with colorful text (ARE)                |
            these ARE some lines                    |
            with colorful text (ARE)                |
            these ARE some lines                    |
            with colorful text (ARE)                |
            these ARE some lines                    |
            with colorful text (ARE)                |
            these ARE some lines                    |
            with colorful text (ARE)                |
            these ARE some lines                    |
            with colorful text (ARE)                |
            these ARE some lines                    |
            with colorful text (ARE)                |
            these ARE some lines                    |
            with colorful text (ARE)                |
            these ARE some lines                    |
            with colorful text (ARE)                |
            these ARE some lines                    |
            with colorful text (ARE)                |
            these ARE some lines                    |
            with colorful text (ARE)                |
            these ARE some lines                    |
            with colorful text (ARE)                |
            these ARE some lines                    |
            with colorful text (ARE)                |
            these ARE some lines                    |
            with colorful text (ARE)                |
            these ARE some lines                    |
            with colorful text (ARE)                |
            with colorful text (ARE)                |
            {UNEXPECTED bold = true, reverse = true:[No Name] [+]                           }|
             [    1]these ARE some lines            |
             [    2]these ARE some lines            |
             [    3]with colorful text (ARE)        |
             [    4]these ARE some lines            |
             [    5]with colorful text (ARE)        |
             [    6]these ARE some lines            |
             [    7]with colorful text (ARE)        |
            {UNEXPECTED reverse = true:[live_sub]                              }|
            :%s/are/ARE^                             |
      ]])
        
        feed('\27')
        feed(':%s/some.*/nothing')      -- regex sub, aborted

        screen:expect([[
            these are nothing                       |
            with colorful text (are)                |
            these are nothing                       |
            with colorful text (are)                |
            these are nothing                       |
            with colorful text (are)                |
            these are nothing                       |
            with colorful text (are)                |
            these are nothing                       |
            with colorful text (are)                |
            these are nothing                       |
            with colorful text (are)                |
            these are nothing                       |
            with colorful text (are)                |
            these are nothing                       |
            with colorful text (are)                |
            these are nothing                       |
            with colorful text (are)                |
            these are nothing                       |
            with colorful text (are)                |
            these are nothing                       |
            with colorful text (are)                |
            these are nothing                       |
            with colorful text (are)                |
            these are nothing                       |
            with colorful text (are)                |
            these are nothing                       |
            with colorful text (are)                |
            these are nothing                       |
            with colorful text (are)                |
            {UNEXPECTED bold = true, reverse = true:[No Name] [+]                           }|
             [    1]these are nothing               |
             [    2]these are nothing               |
             [    4]these are nothing               |
             [    6]these are nothing               |
             [    8]these are nothing               |
             [   10]these are nothing               |
             [   12]these are nothing               |
            {UNEXPECTED reverse = true:[live_sub]                              }|
            :%s/some.*/nothing^                      |
       ]])

        feed('\27')
        feed(':%s/some.*/nothing\n')      -- regex sub, validated

        screen:expect([[
            these are nothing                       |
            with colorful text (are)                |
            these are nothing                       |
            with colorful text (are)                |
            these are nothing                       |
            with colorful text (are)                |
            these are nothing                       |
            with colorful text (are)                |
            these are nothing                       |
            with colorful text (are)                |
            these are nothing                       |
            with colorful text (are)                |
            these are nothing                       |
            with colorful text (are)                |
            these are nothing                       |
            with colorful text (are)                |
            these are nothing                       |
            with colorful text (are)                |
            these are nothing                       |
            with colorful text (are)                |
            these are nothing                       |
            with colorful text (are)                |
            these are nothing                       |
            with colorful text (are)                |
            these are nothing                       |
            with colorful text (are)                |
            these are nothing                       |
            with colorful text (are)                |
            these are nothing                       |
            with colorful text (are)                |
            these are nothing                       |
            with colorful text (are)                |
            these are nothing                       |
            with colorful text (are)                |
            these are nothing                       |
            with colorful text (are)                |
            these are nothing                       |
            with colorful text (are)                |
            ^these are nothing                       |
                                                    |
       ]])

        feed('i')
        feed('example of insertion')

        screen:expect([[
            these are nothing                       |
            with colorful text (are)                |
            these are nothing                       |
            with colorful text (are)                |
            these are nothing                       |
            with colorful text (are)                |
            these are nothing                       |
            with colorful text (are)                |
            these are nothing                       |
            with colorful text (are)                |
            these are nothing                       |
            with colorful text (are)                |
            these are nothing                       |
            with colorful text (are)                |
            these are nothing                       |
            with colorful text (are)                |
            these are nothing                       |
            with colorful text (are)                |
            these are nothing                       |
            with colorful text (are)                |
            these are nothing                       |
            with colorful text (are)                |
            these are nothing                       |
            with colorful text (are)                |
            these are nothing                       |
            with colorful text (are)                |
            these are nothing                       |
            with colorful text (are)                |
            these are nothing                       |
            with colorful text (are)                |
            these are nothing                       |
            with colorful text (are)                |
            these are nothing                       |
            with colorful text (are)                |
            these are nothing                       |
            with colorful text (are)                |
            these are nothing                       |
            with colorful text (are)                |
            example of insertion^these are nothing   |
            {6:-- INSERT --}                            |
       ]])
        
    end)

end)
