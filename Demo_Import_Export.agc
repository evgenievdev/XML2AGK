
// Project: XML Parser 
// Created: 2017-06-10
global debug$
// set window properties
SetWindowTitle( "XML Parser" )
SetWindowSize( 1024, 768, 0 )

// set display properties
SetVirtualResolution( 1024, 768 )
SetOrientationAllowed( 1, 1, 1, 1 )

SetPrintSize(14)

#include "Include/XML_Parser.agc"

local xml as integer

SetFolder("/")
t1# = Timer()
rem Return the index of the xml file
xml = XML_Load_File( 'demo.xml' , 'demo' )
t2# = Timer()

//XML_Loaded[ xml ].levels[1].nodes[2].comment = ' Some random comment here'


local attrs as XML_Attribute[ 5 ]

attrs[5].name="prop"

local args as XML_Attribute[]
while XML_Set_Next_Node( xml ) = XML_TRUE

	args = XML_Get_Node_Attributes( xml )

endwhile 
 
 



t3# = Timer()

newXML = OpenToWrite( "demo_new.xml" , 0 )

export = XML_Export( "demo" , newXML , 1 , 1 )

CloseFile( newXML )

t4# = Timer()
 
 
t5# = timer()
 XML_Add_Child_Node( xml , "test" , "valuess" , attrs , "some comment for this node" , XML_FALSE )
t6# = timer()

do
  
    print( "XML Load = " + Str( (t2# - t1#)*1000 ) + "ms"  )
    print( "XML Export = " + Str( (t4# - t3#)*1000 ) + "ms"  )
	  print( "Add Node = "+ Str( (t6# - t5#)*1000 ) + "ms"  )
    
	
	print(debug$)
 
    Print( ScreenFPS() )
    Sync()
loop
