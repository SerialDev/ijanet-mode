# ijanet-mode Interactive Janet mode

# Installation:

```
Follow the great instructions at https://github.com/janet-lang/janet
```

# Obligatory gif 

![image info](/img/repl.gif)



I highly recommend using the straight package manager

```
(straight-use-package
 '(ijanet
   :type git
   :host github
   :repo "serialdev/ijanet-mode"
))
```

Alternatively pull the repo and add to your init file
```
git clone https://github.com/SerialDev/ijanet-mode
```

## Hard Requirements
Janet is required 


# Current functionality:
## NOTE: These will be active when a major mode janet-mode has been defined
## for now use the functions or allocate your own keybindings
```
C-c C-p [Start repl] (ijanet)
C-c C-b [Eval buffer] (ijanet-eval-buffer)
C-c C-l [Eval line] (ijanet-eval-line)
C-c C-r [eval region] (ijanet-eval-region)
```
