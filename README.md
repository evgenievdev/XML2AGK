# XML2AGK

XML Parser for App Game Kit (Tier 1). Tested and developed for AGK V2, however it is also backwards compatible with V1.

This library is written for Tier 1 app development using Basic.

It works using a dynamic array (XML_Loaded[]) which stores any XML files you load into your application and can be accessed at any time.
Each XML file is divided into nesting levels and nodes within each nesting level. The library works with simple array indexes or assigned keys for each file for dynamic access (similar to a hash table).

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

2) Creating a blank XML file
  - XML_Create( key as string ) : Create a new blank xml file within your application and give it a unique name reference (key parameter) ; You can access this file later by calling the XML_Get_Index() function and supplying the name you created as a parameter
   

3) Exporting/Saving XML
  - Open a file to write in your application using OpenToWrite( file , append )
  - Call XML_Export( key as string , file as integer , useTabs as integer , rowSpacing as integer ) on that file
    - key is the name reference you gave that file when you loaded it
    - file is the variable where you called the OpenToWrite method
    - useTabs : set to true if you want to add tabulation based on the nesting level of each element (gives the file a nice organized structure)
    - rowSpacing : the number of lines of empty space left between nodes (can be used to accomodate for extra space for comments)
    
    **NOTE:** Due to the way AGK deals with file reading/writing, if you use OpenToWrite to save the XML file it will be located in _C:\Users\your_username\AppData\Local\AGKApps\your_project_name\_ folder if you are using Windows. 
    
Example:
```
newXML = OpenToWrite( "demo_new.xml" , 0 )
export = XML_Export( "demo" , newXML , 1 , 1 )
```

4) Removing XML file from application
 - To remove a loaded file from your application's memory, call the XML_Remove function ; You need the array index of the file ; If you don't know the array index but know the key reference you have used when loading/creating the file, call the XML_Get_Index( key ) method to get the array index
```
XML_Remove( id as integer )
```

---

**Loaded XML files are kept in a dynamic array XML_Loaded. This array can be accessed directly or through the provided methods below**

A) GET Functions

- XML_Get_Index( xmlKey as string ) : Return the array index of the loaded xml file ; returns -1 if nothing is found
- XML_Get_Node_Attributes( xmlID as integer ) : Get the currently set node's list of attributes based on the xml file index supplied by XML_Get_Index() ; returned format is an array of type XML_Attribute
- XML_Get_Node_Attribute( xmlID as integer , attribute as string ) : Get the value of a specific attribute from the currently set node ; returned value is in string format
    
B) SET Functions

- XML_Set_First_Child_Node( xmlID as integer ) : Set the current node to be the first child of the previously set node (i.e. go one nesting level deeper) : returns -1 if there are no more nesting levels there, otherwise returns 1
- XML_Set_Next_Node( xmlID as integer ) : Find the next node within the CURRENT nesting level ; Returns -1 if the LAST node is reached , otherwise it returns 1 (useful if you want to loop through a nest's nodes using while loop)
- XML_Set_Previous_Node( xmlID as integer ) : Find the previous node within the CURRENT nesting level ; Returns -1 if the FIRST node is reached , otherwise it returns 1
- XML_Set_Parent_Node( xmlID as integer ) : Set the current node to be the previously set node's parent (i.e. go one nesting level back) ; returns -1 if there are no nodes before the current one (i.e. this is the root node) , otherwise returns 1

C) ADD Functions

- XML_Add_Child_Node( xmlID as integer , nodeName as string , nodeValue as string , nodeAttr as XML_Attribute[] , comment as string , setAsActive as integer ) : _Add a new node to an already existing XML file loaded in your app (this only adds the data in the app, it doesn't overwrite anything in the actual file unless you decide to call the Export method)_
  - xmlID : the array index of the xml file you wish to edit (if you dont know the index but know the name reference use XML_Get_Index()
  - nodeName : the name of the new node you wish to create
  - nodeValue : The value between the opening and closing tags of the node (e.g. <node> node value here </node>) ; If you want to leave it empty, just write "" 
  - nodeAttr : An array of type XML_Attribute which holds all the attributes you wish to add for this node (each attribute can be assigned a name and a value)
  - comment : If you want you can add a comment above the node in your xml file (only visible when exporting)


---

**Using different charsets**
Loading/Exporting a file with a different charset should work for most cases automatically as long as:
  1) If you are loading a file with a different charset from standard, make sure it is saved in an appropriate charset type in your text editor
  2) If you are saving a file with a different charset, make sure your application supports it
  
As an example, the following XML file written in Cyrillic should work fine in UTF-8:
```
<кирилица>
	<таг>
		<гнездо едно="казвам" две="се" три="Иван" />
	</таг>
</кирилица>
```


**Creating custom file format**

If you wish to create your own custom format, all you have to do is replace the constant values in the beginning of the XML_Parser.agc library.
```
#constant XML_CHAR_OPENING_BRACKET "<" // First character in node - ascii 60
#constant XML_CHAR_CLOSING_BRACKET ">" // Last character in node - ascii 62
#constant XML_CHAR_CLOSING_SLASH "/" // Node closing slash (second last character) - ascii 47
#constant XML_CHAR_ATTR_DELIMITER "=" // Attribute delimiter (attribute="value") - ascii 61
#constant XML_CHAR_QUOTATION '"' // Quotation format for attributes - ascii 34 (double quotes) ; 39 (single quotes)
#constant XML_CHAR_TAB "	" // Tabulation - ascii 9
#constant XML_CHAR_SPACE " " // Single space - ascii 32
#constant XML_CHAR_COMMENT "!" // Comment block - ascii 33
#constant XML_CHAR_HEADER "?" // Header - ascii 63
```

For example, if you want your nodes to have the following format:
```
[node]
  [sub1]
    [sub3] Some Value [/sub3]
  [/sub2]
[/sub1]
```
All you have to do is change the XML_CHAR_OPENING_BRACKET from "<" to "[" and the XML_CHAR_CLOSING_BRACKET from ">" to "]"
You can use this line of reasoning for the rest of the constants, but they must be consistent and you must make sure to avoid conflict between them.
