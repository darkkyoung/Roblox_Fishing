-- Validation only: independently decode the actual binary build, never rewrite it.
-- Requires rbxmk 0.9.1. No Studio or network APIs are used.
local source, destination = ...
assert(type(source) == "string" and type(destination) == "string")
local place = fs.read(source, "rbxl")
fs.write(destination, place:GetChildren(), "rbxlx")
-- Preserve script bytes separately: rbxmk's XML string encoder treats raw UTF-8
-- bytes as Latin-1 when there is no engine descriptor. JSON retains UTF-8 here.
local sources = {}
for _, object in ipairs(place:GetDescendants()) do
    if object.ClassName == "Script" or object.ClassName == "LocalScript" or object.ClassName == "ModuleScript" then
        table.insert(sources, tostring(object.Source))
    end
end
fs.write(destination .. ".sources.json", sources, "json")
