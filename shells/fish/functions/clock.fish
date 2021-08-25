function clock --wraps='tty-clock -sct -C 4' --description 'alias clock=tty-clock -sct -C 4'
  tty-clock -sct -C 4 $argv; 
end
