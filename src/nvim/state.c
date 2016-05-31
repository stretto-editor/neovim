#include <assert.h>

#include "nvim/lib/kvec.h"

#include "nvim/state.h"
#include "nvim/vim.h"
#include "nvim/getchar.h"
#include "nvim/ui.h"
#include "nvim/os/input.h"

#include "nvim/ex_getln.h"
#include "nvim/ex_docmd.h"

#ifdef INCLUDE_GENERATED_DECLARATIONS
# include "state.c.generated.h"
#endif


void state_enter(VimState *s)
{
  char_u live_cmd[255] = ""; //TODO : check size
  int i = 0;
  
  for (;;) {
    int check_result = s->check ? s->check(s) : 1;
    
    // TODO:live parse cmd to know if this is a sub
    
    if (!check_result) {
      break;
    } else if (check_result == -1) {
      continue;
    }
    
    int key;
    
  getkey:
    if (char_avail() || using_script() || input_available()) {
      // Don't block for events if there's a character already available for
      // processing. Characters can come from mappings, scripts and other
      // sources, so this scenario is very common.
      key = safe_vgetc();
    } else if (!queue_empty(loop.events)) {
      // Event was made available after the last queue_process_events call
      key = K_EVENT;
    } else {
      input_enable_events();
      // Flush screen updates before blocking
      ui_flush();
      // Call `os_inchar` directly to block for events or user input without
      // consuming anything from `input_buffer`(os/input.c) or calling the
      // mapping engine. If an event was put into the queue, we send K_EVENT
      // directly.
      (void)os_inchar(NULL, 0, -1, 0);
      input_disable_events();
      key = !queue_empty(loop.events) ? K_EVENT : safe_vgetc();
    }
    
    // append to cmd_line
    live_cmd[i++] = (char_u)key;
    live_cmd[i] = '\0';
    
    //TODO : execute if this is a sub with do_live_sub
    
    if (key == K_EVENT) {
      may_sync_undo();
    }
    
    int execute_result = s->execute(s, key);
    int is_sub = 0;
    
    if( EVENT_COLON == 1 && execute_result == 1) {
      if (live_cmd[0] == 's'
          || (live_cmd[0] == '%' && live_cmd[1] == 's')) {
        is_sub = 1;
      }
    }
    
    if (EVENT_COLON == 1 && is_sub) {
      do_cmdline(live_cmd, NULL, NULL, DOCMD_KEEPLINE);
    }
    
    if (!execute_result) {
      break;
    } else if (execute_result == -1) {
      goto getkey;
    }
  }
}
