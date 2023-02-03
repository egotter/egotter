require 'irb/completion'
require 'irb/ext/save-history'

IRB.conf[:USE_AUTOCOMPLETE] = false
IRB.conf[:SAVE_HISTORY] = 10000
IRB.conf[:HISTORY_FILE] = File.expand_path('~/.irb_history')
