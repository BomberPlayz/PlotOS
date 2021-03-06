local shell = require("shell")
local tty = require("tty")
local fs = require("filesystem")

local inet = require("internet")

local response = inet.request("https://raw.githubusercontent.com/BomberPlayz/PlotOS/master/ver")
local body = ""
for chunk in response do
  body = body .. chunk
end

for line in io.lines("/ver") do
  if not body == line then
    shell.execute("/home/posinst")
  end
end

if tty.isAvailable() then
  if io.stdout.tty then
    io.write("\27[40m\27[37m")
    tty.clear()
  end
end
dofile("/etc/motd")

shell.setAlias("dir", "ls")
shell.setAlias("move", "mv")
shell.setAlias("rename", "mv")
shell.setAlias("copy", "cp")
shell.setAlias("del", "rm")
shell.setAlias("md", "mkdir")
shell.setAlias("cls", "clear")
shell.setAlias("rs", "redstone")
shell.setAlias("view", "edit -r")
shell.setAlias("help", "man")
shell.setAlias("cp", "cp -i")
shell.setAlias("l", "ls -lhp")
shell.setAlias("..", "cd ..")
shell.setAlias("df", "df -h")
shell.setAlias("grep", "grep --color")
shell.setAlias("more", "less --noback")
shell.setAlias("reset", "clear; resolution `cat /dev/components/by-type/gpu/0/maxResolution`")

os.setenv("EDITOR", "/bin/edit")
os.setenv("HISTSIZE", "10")
os.setenv("HOME", "/home")
os.setenv("IFS", " ")
os.setenv("MANPATH", "/usr/man:.")
os.setenv("PAGER", "less")
os.setenv("PS1", "\27[40m\27[33m$HOSTNAME$HOSTNAME_SEPARATOR$PWD\27[40m\27[31m # \27[37m")
os.setenv("LS_COLORS", "di=0;36:fi=0:ln=0;33:*.lua=0;32")

shell.setWorkingDirectory(os.getenv("HOME"))

local home_shrc = shell.resolve(".shrc")
if fs.exists(home_shrc) then
  loadfile(shell.resolve("source", "lua"))(home_shrc)
end

local net = require("internet")
for line in io.lines("/ver") do
 if not line == net.request("https://raw.githubusercontent.com/BomberPlayz/PlotOS/master/ver") then
  print("It is recommanded to update PlotOS from "..io.lines("/ver")[1].." to "..net.request("https://raw.githubusercontent.com/BomberPlayz/PlotOS/master/ver"))
 end
end
