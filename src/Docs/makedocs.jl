#! /usr/bin/env julia
module MakeDocs

#-----------------------------------------------------------------------------------
# Type definitions
#-----------------------------------------------------------------------------------

type FuncDoc
  name :: String
  text :: String
  modn :: String
  file :: String
end

type ModDoc
  name  :: String
  fdocs :: Vector{FuncDoc}
  file  :: String
end

type DocFile
  name :: String
  mods :: Vector{ModDoc}
end

type DocDatabase
  files :: Vector{DocFile}
  fdocs :: Dict{String, FuncDoc}
  mods  :: Dict{String, ModDoc}
end

#-----------------------------------------------------------------------------------
# Database construction
#-----------------------------------------------------------------------------------

function DocDatabase(filelist)
  files = read_files(filelist)
  docdb = DocDatabase(files, Dict{String, ModDoc}(), Dict{String, FuncDoc}())
  for file in docdb.files
    for mod in file.mods
      docdb.mods[mod.name] = mod
      for fdoc in mod.fdocs
        docdb.fdocs[fdoc.name] = fdoc
      end
    end
  end
  add_references!(docdb)
  return docdb
end

function read_files(filelist)
  filedocs = DocFile[]
  for file in filelist
    if !(file in ["makedocs.jl", "Docs.jl"]) && endswith(file, ".jl")
      push!(filedocs, make_file_doc(file))
    end
  end
  filedocs
end

function make_file_doc(filename)
  file = open(filename)
  text = unescape_string(readall(file))
  mods = ModDoc[]
  while text != ""
    mname, text   = capture(text, from="# ", until=";")
    modtext, text = capture(text, from="#-", until="#-")
    global res = (modtext)

    fdocs = FuncDoc[]
    while modtext != ""
      fhelp, modtext = capture(modtext, from="\"\"\"", until="\"\"\"")
      fname, modtext = capture(modtext, from="", until=";")
      fname  = replace(strip(fname), ":@", "@")
      fname != "" && push!(fdocs, FuncDoc(fname, fhelp, strip(mname), filename[1:end-3]))
    end
    push!(mods, ModDoc(strip(mname), fdocs, filename[1:end-3]))
  end
  close(file)
  DocFile(filename[1:end-3], mods)
end

function add_references!(docdb)
  for fdoc in values(docdb.fdocs)
    for mention in get_mentions(fdoc.text)
      if haskey(docdb.fdocs, mention) && mention != fdoc.name
        fun  = docdb.fdocs[mention]
        link = replace(lowercase(fun.name), r"^@", "")
        ref  = "[`$(fun.name)`](./$(fun.file).md#$(link))"
        fdoc.text = replace(fdoc.text, "`$mention`", ref)
      end
    end
  end
end

function get_mentions(text)
  mentions = Set{String}()
  while text != ""
    mention, text = capture(text, from="`", until="`")
    mention != "" && push!(mentions, mention)
  end
  return mentions
end

#-----------------------------------------------------------------------------------
# Write to markdown file
#-----------------------------------------------------------------------------------

function write_database(docdb::DocDatabase, directory)
  for filedoc in docdb.files
    write_file(filedoc, directory)
  end
  println("Success!")
end

function write_file(filedoc::DocFile, directory)
  filename = filepath(filedoc, directory)

  println("Creating $filename... ")
  make_directory(directory, "lib")

  open(filename, "w") do output
    for mod in filedoc.mods
      write_module(output, mod)
    end
  end
end

function write_module(output, mod)
  write(output, mod.name)
  write(output, "\n==========\n\n")
  for fdoc in mod.fdocs
    write(output, prepare_name(fdoc.name))
    write(output, prepare_text(fdoc.text))
  end
  write(output, "\n\n")
end

function prepare_name(name)
  name = "#### $name\n"
end

function prepare_text(text)
  text =  strip(text)
  text = "\n$text\n\n---\n"
end

filepath(filedoc, dir) =
  dir == pwd()?
    joinpath("lib", "$(filedoc.name).md") :
    joinpath(dir, "lib", "$(filedoc.name).md")


#-----------------------------------------------------------------------------------
# Utilities
#-----------------------------------------------------------------------------------

function capture(str; from="", until="")
  for i in eachindex(str)
    if startswith(str[i:end], from)
      str = str[i:end]
      break
    end
  end

  str = replace(str, from, "", 1)
  res = str

  for i in eachindex(str)
    if endswith(str[1:i], until)
      res = str[1:i]
      break
    end
  end
  len = last(collect(eachindex(res*"a")))
  res = reverse(replace(reverse(res), reverse(until), "", 1))

  return res, str[len:end]
end

function make_directory(path...)
  path = joinpath(path...)
  isdir(path) || mkdir(path)
end

#-----------------------------------------------------------------------------------
# Main
#-----------------------------------------------------------------------------------

function main()
  compile(readdir(pwd()), joinpath("..","..","docs"))
end

function compile(from, to)
  docdb = DocDatabase(from)
  write_database(docdb, to)
end


if !isinteractive()
   main()
end

#-----------------------------------------------------------------------------------

end
