# XML2AGK

XML Parser for App Game Kit (Tier 1). Tested and developed for AGK V2, however it is also backwards compatible with V1.

This library is written for Tier 1 app development using Basic.

All you have to do is include the source file in your application like this and follow the usage instructions below

```
#include "Include/XML_Parser.agc"
```

---

**Features**
1) Load XML file into local repository 
2) Edit any of the loaded xml files on the fly and save the changes
3) Create XML files from scratch and add nodes to them
4) No hardcoded limits on nesting or number of files loaded within the application
5) Universal charset support (not fully tested yet)
6) Ability to create your own custom nested format

**Usage**

1) Loading XML
  - (optional) create a variable of type integer and use it to store the returned array index of the XML_Load_File() function
  - call XML_Load_File( xmlFile as string , key as string ) function. 
    - The first parameter is the path to your xml file, the second parameter is a unique name you give to your xml file for future reference when accessing it dynamically in your application (useful if you load/close files a lot and don't want to keep track of array index changes) 
    
Example: 
```
local xml as integer
xml = XML_Load_File( 'demo.xml' , 'demo' )
```

2) Exporting/Saving XML
  - Open a file to write in your application using OpenToWrite( file , append )
  - Call XML_Export( key as string , file as integer , useTabs as integer , rowSpacing as integer ) on that file
    - key is the name reference you gave that file when you loaded it
    - file is the variable where you called the OpenToWrite method
    - useTabs : set to true if you want to add tabulation based on the nesting level of each element (gives the file a nice organized structure)
    - rowSpacing : the number of lines of empty space left between nodes (can be used to accomodate for extra space for comments)
    
Example:
```
newXML = OpenToWrite( "demo_new.xml" , 0 )
export = XML_Export( "demo" , newXML , 1 , 1 )
```
    
