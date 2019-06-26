
//###############################################
//#
//#   now here are some helpfull functions.
//#   simply copy&paste them to your own script.
//#
//###############################################

 //////////////////////////////////////
// get the WorkingDirectory

STARTDIR = getstartpath()


 /////////////////////////////////////////
//

function GetWinIDbyName( name )
  DIM mylist =  {}
  DIM i
  DIM winid
  DIM winname
  mylist = xwin_listwindows()

  for i = 0 to count(mylist)-1
    winid = cutrightfromleft( mylist[i] , " " )
    winname = cutleft ( mylist[i] , " " )
    'print mylist[i] & "---"

    if winname = name then   
      'print "---------------------------------" & name
      'break
      
      return winid
    end if

  next
  mylist =  {}
  return 0

end function

 //////////////////////////////////////////////////////////////////////
//   remove temporary files 

sub cleanup()
  removefile( "/tmp/wxbxdmenu.tmp" )
  removefile( "/tmp/gtkwindow.script" )
end sub


 //////////////////////////////////////////////////////////////////////
//   make it easier to run Xmessage

function xmessage( themessage )
  DIM xmresult
  DIM xmchoice
  xmresult = xwin_exec( "xmessage -print " & themessage & "  1>/tmp/wxbxdmenu.tmp" )
  xmchoice = readfiletail( "/tmp/wxbxdmenu.tmp" )
  cleanup()
  //if xmchoice = nothing then xmchoice = "-1"
  return xmchoice

end function

 //////////////////////////////////////////////////////////////////////
//   make it easier to run Xdialog

function xdialog( xdmsg )
  DIM xdresult
  DIM xdchoice
  xdresult = xwin_exec( "Xdialog " & xdmsg & " 2> /tmp/wxbxdmenu.tmp" )
  xdchoice = readfiletail( "/tmp/wxbxdmenu.tmp" )
  cleanup()
  return xdresult , xdchoice

end function


 //////////////////////////////////////////////////////////////////////
//   make it easier to run Gtkdialog

function gtkdialog( gtkwindowstring )


  DIM   gtktitleindex = instr( gtkwindowstring , "=" )
  DIM   gtktitle = left ( gtkwindowstring , gtktitleindex-1 )
  'gtktitle = replace ( gtktitle , "export " , "" )

   'gtkwindowstring = "#!/bin/sh\n##!/usr/local/bin/gtkdialog -f\n" &gtkwindowstring

  gtkwindowstring =  "#!/bin/sh\nexport " & gtkwindowstring
  gtkwindowstring &=  "gtkdialog3 --program " & gtktitle & "\n"
  gtkwindowstring &=  "unset "  & gtktitle & "\n"

  writestringtofile ( "/tmp/gtkwindow.script" , gtkwindowstring )
  DIM   gtkresult = xwin_exec( "sh /tmp/gtkwindow.script 1> /tmp/wxbxdmenu.tmp" )
  DIM   gtkchoice = readfiletail( "/tmp/wxbxdmenu.tmp" )
  cleanup()
  return gtkchoice

end function

 //////////////////////////////////////////////////////////////////////
//   make it easier to run Gtkdialog 0.59.8

function gtkdialog2( gtkwindowstring )

  DIM   gtktitleindex = instr( gtkwindowstring , "=" )
  DIM   gtktitle = left ( gtkwindowstring , gtktitleindex-1 )
  'gtktitle = replace ( gtktitle , "export " , "" )

  if left( gtkwindowstring , 11 ) != "MAIN_DIALOG" then

    DIM   gtkoldtitle = cutrightfromleft( gtkwindowstring , "=" )  
    gtkwindowstring = cutleft( gtkwindowstring , "=" )

    DIM gtkfirstchar = left( gtkwindowstring , 1 )
    gtkwindowstring = right(gtkwindowstring , len(gtkwindowstring)-1)
    gtkwindowstring = "MAIN_DIALOG=" & gtkfirstchar & "\n<wtitle>" & gtkoldtitle & "</wtitle>\n" & gtkwindowstring

  end if

   'gtkwindowstring = "#!/bin/sh\n##!/usr/local/bin/gtkdialog -f\n" &gtkwindowstring

  gtkwindowstring =  "#!/bin/sh\nexport " & gtkwindowstring
  gtkwindowstring &=  "gtkdialog2 --program " & "MAIN_DIALOG" & "\n"
  gtkwindowstring &=  "unset "  & "MAIN_DIALOG" & "\n"

  writestringtofile ( "/tmp/gtkwindow.script" , gtkwindowstring )
  DIM   gtkresult = xwin_exec( "sh /tmp/gtkwindow.script 1> /tmp/wxbxdmenu.tmp" )
  DIM   gtkchoice = readfiletail( "/tmp/wxbxdmenu.tmp" )
  cleanup()
  return gtkchoice

end function


 //////////////////////////////////////////////////////////////////////
//   save string to a file

function writestringtofile( thefile , thestring )

  open thefile for output as #1
     print #1 , thestring
  close #1

end function

 //////////////////////////////////////////////////////////////////////
//   append string to a file

function appendstringtofile( thefile , thestring )

  open thefile for append as #1
     print #1 , thestring
  close #1

end function


 //////////////////////////////////////////////////////////////////////
//   save list to a file

function writelisttofile( thefile , thelist )
  DIM theline
  open thefile for output as #1
     for each theline in  thelist 
       print #1 , theline
     next
  close #1

end function

 //////////////////////////////////////////////////////////////////////
//   append list to a file

function appendlisttofile( thefile , thelist )
  DIM theline
  open thefile for append as #1
     for each theline in  thelist 
       print #1 , theline
     next
  close #1

end function


 //////////////////////////////////////////////////////////////////////
//   read in a file to a string

function readfile( thefile )

  if fileexists( thefile ) then
     DIM freeNum= freeFile()
     DIM text = ""
     DIM buffer 
     open thefile For Input As #freeNum
        while ! eof( freeNum )
          Line Input #freeNum, buffer
          text &= buffer
       end while
     close #freeNum
  end if
  return( text )
end function

 //////////////////////////////////////////////////////////////////////
//   read in a templatefile to a string

function readtemplate( thefile )

  if fileexists( thefile ) then
     DIM freeNum= freeFile()
     DIM text = ""
     DIM buffer 
     open thefile For Input As #freeNum
        while ! eof( freeNum )
          Line Input #freeNum, buffer
          text &= buffer & "\n"
       end while
     close #freeNum
  end if
  return( text )
end function

 //////////////////////////////////////////////////////////////////////
//   read in a file to a list

function readfiletolist( thefile )
  DIM   thelist = {}
  if fileexists( thefile ) then
     DIM freeNum= freeFile()
     DIM text = ""
     open thefile For Input As #freeNum
        DIM c = 0
        DIM buffer 
        while ! eof( freeNum )
          Line Input #freeNum, buffer
          thelist[c] = buffer
          c+=1
       end while
     close #freeNum
  end if
  return( thelist )
end function


 //////////////////////////////////////////////////////////////////////
//   read in last line of a file

function readfiletail( thefile )

  if fileexists( thefile ) then
     DIM freeNum= freeFile()
     DIM buffer
     open thefile For Input As #freeNum
        while ! eof( freeNum )
          Line Input #freeNum, buffer
       end while
     close #freeNum
  end if
  return( buffer )
end function

  ////////////////////////////////////////////////////////////////////////////////////
 // 
//    get the path of this script, so that it will find its resources
//    (e.g. Icons)

function getstartpath()

   DIM full = command(2)
   if left ( full , 1 ) != "/" then return "./"
   return cutright( full , "/" ) 

end function

  ////////////////////////////////////////////////////////////////////////////////////
 // 
//    return left part of a string, counting the seperator from right

function cutright( thestring , splitter )

    DIM x = rinstr( thestring , splitter )
    DIM thepath = left( thestring , x-1 )

    return thepath

end function

  ////////////////////////////////////////////////////////////////////////////////////
 // 
//    return left part of a string, counting the seperator from left

function cutrightfromleft( thestring , splitter )

    DIM x = instr( thestring , splitter )
    DIM thepath = left( thestring , x-1 )

    return thepath

end function

  ////////////////////////////////////////////////////////////////////////////////////
 // 
//    return right part of a string, counting the seperator from left

function cutleft( thestring , splitter )

    DIM x = instr( thestring , splitter )
    DIM thepath = right( thestring , len(thestring)-x-len(splitter)+1 )
    'print "---" & thepath

    return thepath

end function



  //////////////////////////////////////////////////////////////////////
 //   explode separates a string using splitter
//    and returns the substrings in a list
//
//  EXAMPLE: 
//
//  mystring = "dogs,puppys,cats"
//  words = {}
//  words = explode( mystring , ",")
//  print words[2] // lists start count at 0


function explode(wholestr,splitter)
    dim word={}
    DIM spos=0
    DIM i=1
    DIM n=instr(0,wholestr,splitter)
    word[0]=left(wholestr,n-1)
    n=instr(spos,wholestr,splitter)
    spos=n+length(splitter)
    while instr(spos,wholestr,splitter)
      n=instr(spos,wholestr,splitter)
      word[i]=mid (wholestr,spos,n-spos)
      spos=n+length(splitter)
      i+=1
    end while
    word[i]=mid (wholestr,n+length(splitter),length(wholestr))
    return word
end function


  //////////////////////////////////////////////////////////////////////
 //   remove/delete a file
//    

function removefile( thefile )

  if thefile = "" then return 1
  if ! fileexists( thefile ) then return 1
  //result = xwin_exec( "rm -f " & thefile ) // this does not work. why?
  shell( "rm -f " & thefile )
  if fileexists( thefile ) then return 1

  return 0

end function

  //////////////////////////////////////////////////////////////////////
 //   delete all HTML-TAGS from a string
//    
function removehtml( thestring )


   //--- delete Links ---
   DIM category = replace (  thestring , "<" , "<REMOVE" )
   category = replace (  category , ">" , "<" )
   DIM categorywithlinks = explode( category , "<" )

   DIM thenewstring = ""
   DIM part 
   for each part in categorywithlinks
     if left( part , 6 ) != "REMOVE" then
        thenewstring &= part
     end if
   next
  thenewstring = replace(  thenewstring , "&#8734;" , "" )
  return thenewstring

end function


  //////////////////////////////////////////////////////////////////////
 //   rewrite HTML-TAGS to a shorter style
//  
function rewritelinks( thestring )


   //--- delete Links ---
   thestring = replace (  thestring , "<a href=" , "[" )
   thestring = replace (  thestring , "<a class=\"ext\" href=" , "[" )
   thestring = replace (  thestring , "<a " , "[" )
   thestring = replace (  thestring , " href=" , "" )
   thestring = replace (  thestring , "href=" , "" )
   thestring = replace (  thestring , "class=\"missingpage\"" , "" )

   thestring = replace (  thestring , "</a>" , "]" )

  return thestring

end function

  //////////////////////////////////////////////////////////////////////
 //   Bubblesort
//  
function bubblesort( thelist )

  DIM i
  DIM inOrderFlag
  DIM j
  For i = thelist.Count() to 1 step -1
     inOrderFlag = true
     For j = 0 to thelist.Count() - 2
          If thelist[j] > thelist[j + 1] then
           inOrderFlag = false
           thelist[j], thelist[j + 1] = thelist[j + 1], thelist[j]
          End If
     End For
     If inOrderFlag then break
  End For 

  return thelist

end function


function argvtostring( )

  DIM   i=3
  DIM   args=""
  while command(i) !=""
  args &= command(i) & " "
  i+=1
  wend
  args=trim(args)

return args
end function

  ////////////////////////////////////////////////////////////////////////////////////
 // 
//    return right part of a string, counting the seperator from left

function cutleftfromright( thestring , splitter )

    DIM x = rinstr( thestring , splitter )
    DIM thepath = right( thestring , len(thestring)-x-len(splitter)+1 )
    'print "---" & thepath

    return thepath

end function

  //////////////////////////////////////////////////////////////////////
 //   natsort
//  
function natsort( thelist )
  DIM i
  DIM inOrderFlag
  DIM j
  For i = thelist.Count() to 1 step -1
     inOrderFlag = true
     For j = 0 to thelist.Count() - 2
          If lcase(thelist[j]) > lcase(thelist[j + 1]) then
           inOrderFlag = false
           thelist[j], thelist[j + 1] = thelist[j + 1], thelist[j]
          End If
     End For
     If inOrderFlag then break
  End For 

  return thelist

end function


  //////////////////////////////////////////////////////////////////////
 //   reducelist
//  remove double entries

function reducelist( bf_thelist )

  dim bf_newlist = {}
  bf_newlist[0] = bf_thelist[0]
  dim bf_newlistcounter = 1
  dim bf_i
  for bf_i = 1 to count(bf_thelist)-1
    if bf_thelist[bf_i] != bf_thelist[bf_i - 1] then
      bf_newlist[bf_newlistcounter] = bf_thelist[bf_i] 
      bf_newlistcounter += 1
    end if
  next
  bf_thelist = {}
  return bf_newlist

end function