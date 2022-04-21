# BashMan

## A bash powered project manager

### Built with

[jq](https://github.com/stedolan/jq)

### Install
First clone the project

```
git clone https://github.com/h2n0/BashMan
```

Then set an alias in  
`~/.bashrc`

```
alias bashman = 'source BashMan/main.sh'
```
'bashman' is just what I call the program, your alias can be anything e.g. `projects`, `projman`

You can now open a new terminal and type `bashman` to get going or
run 
```
source ~/.bashrc
``` 
to run `bashman` in the same terminal


### Commands
- Basic
    - `init` Initialise current directory as a project
    - `void` Remove the project in the current direcoty or selected directory
    - `list` Show all projects in the data file
- Advanced
    - `mark` Mark the project of the current directory as the main project
    - `back` Jump to the marked project directory
    - `goto` Jump to the selected project directory
    - `data` Show the current projects data contense (Not editable!)
- Other
    - `todo` Show / Create current directory project or selected project TODOs