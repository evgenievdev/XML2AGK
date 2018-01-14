/*

	XML Parser for AGK2 [Tier 1] 
	
	Author : I.Liksov
	E-mail : evgeniev.dev@gmail.com

*/

#constant XML_ROOT_NODE "__root__"
#constant XML_ROOT_NODE_UUID "0"
#constant XML_UNDEFINED "__undefined__"
#constant XML_FALSE -1
#constant XML_TRUE 1

#constant XML_CHAR_OPENING_BRACKET "<" // First character in node - ascii 60
#constant XML_CHAR_CLOSING_BRACKET ">" // Last character in node - ascii 62
#constant XML_CHAR_CLOSING_SLASH "/" // Node closing slash (second last character) - ascii 47
#constant XML_CHAR_ATTR_DELIMITER "=" // Attribute delimiter (attribute="value") - ascii 61
#constant XML_CHAR_QUOTATION '"' // Quotation format for attributes - ascii 34 (double quotes) ; 39 (single quotes)
#constant XML_CHAR_TAB "	" // Tabulation - ascii 9
#constant XML_CHAR_SPACE " " // Single space - ascii 32
#constant XML_CHAR_COMMENT "!" // Comment block - ascii 33
#constant XML_CHAR_HEADER "?" // Header - ascii 63

// Each node, regardless of its nature can have attributes. The number of attributes is theoretically unlimited. 
// Each attribute has a name reference and a value attached, written between quotation marks 
type XML_Attribute
	
	name as string
	value as string
	
endtype

type XML_Node
	
	uuid as string // unique id for this node
	name as string
	format as integer // 1 - <tag attr='val' ... > .. child nodes (multi-line) ... </tag> ; 2 - <tag attr='val' ... /> ; 3 - <tag attr='val' ... > value </tag>
	parent as string
	parentUUID as string // Sometimes node names duplicate within one nesting level. To avoid discrepancies, each child node will be associated to a parent node via uuid 
	value as string
	valueLines as integer[ 0 ] // internal variable used to keep the structural integrity of raw text within brackets when exporting xml
	comment as string // Optional parameter for exporting purposes. Format: <!-- comment here -->
	attributes as XML_Attribute[0]
	
endtype

type XML_Level
	
	nodes as XML_Node[0]
	
endtype

type XML_Structure
	
	// Inserting/removing loaded xml files dynamically requires updating variable references. 
	// To avoid this, each loaded xml file can be accessed via its own unique name.
	key as string
	
	// All filtered xml data (rows) is kept here
	data as string[0]
	
	// <?xml version="1.0" ... ?>
	header as string
	
	levels as XML_Level[0]
	
	// Internal variables storing the currently set level and node within that level
	level as integer
	node as integer
	
endtype

rem All loaded XML files will be stored here
global XML_Loaded as XML_Structure[0]


function XML_Generate_UUID()
	
	local result as string
	local rnd as integer
	
	rnd = Random2()
	
	result = Str( rnd )
	
endfunction result 


function XML_Check_Index( xmlID as integer )
	
	if xmlID <= 0 or xmlID > XML_Loaded.length then exitfunction XML_FALSE
	
endfunction XML_TRUE


function XML_Create( key as string )
	
	// If an xml file with this key already exists, remove it 
	if XML_Get_Index( key ) = XML_TRUE then exitfunction XML_FALSE
	
	local file as XML_Structure
	local level as XML_Level
	local id as integer
	
	file.key = key
	file.level = 0
	file.node = 0
	
	XML_Loaded.insert( file )
	
	id = XML_Loaded.length
	
endfunction id


function XML_Add_Child_Node( xmlID as integer , nodeName as string , nodeValue as string , nodeAttr as XML_Attribute[] , comment as string , setAsActive as integer )
	
	if XML_Check_Index( xmlID ) = XML_FALSE then exitfunction XML_FALSE
	
	local nodeData as XML_Node
	local levelID as integer
	local nodeID as integer
	
	levelID = XML_Loaded[ xmlID ].level	
	nodeID = XML_Loaded[ xmlID ].node
	
	if levelID > 0 and nodeID > 0
		
		nodeData.parent = XML_Loaded[ xmlID ].levels[ levelID ].nodes[ nodeID ].name
		nodeData.parentUUID = XML_Loaded[ xmlID ].levels[ levelID ].nodes[ nodeID ].uuid
		
		// Modify the format of the parent of this node. Since the parent now has atleast one child node, its format should be 1
		XML_Loaded[ xmlID ].levels[ levelID ].nodes[ nodeID ].format = 1
		
	else
		
		// If there is no parent set yet, this is the root level of the xml document.
		nodeData.parent = XML_ROOT_NODE
		nodeData.parentUUID = XML_ROOT_NODE_UUID
		
	endif
	
	nodeData.uuid = XML_Generate_UUID()
	nodeData.name = nodeName
	
	// Format depends if value is added ; 2= <node attr="val" /> ; 3= <node attr="val" ... ></node> ; this will be updated by other functions when adding child nodes or value
	if Len( nodeValue ) > 0
		nodeData.value = nodeValue
		nodeData.format = 3
	else
		nodeData.format = 2
	endif  
	
	// Necessary so the exporter doesn't throw an error
	nodeData.valueLines.insert(1)
	
	if Len( comment ) > 0 
		
		nodeData.comment = comment
		
	endif
	
	// If a node is selected on this level, add the child as part of this node, one level further
	if nodeID > 0 
	 
		levelID = levelID + 1
		
		// If this level does not exist in the array, create it (but only once)
		if levelID > XML_Loaded[ xmlID ].levels.length
		
			local tempLevel as XML_Level
			
			XML_Loaded[ xmlID ].levels.insert( tempLevel )
		
		endif
	
	endif
	
	XML_Loaded[ xmlID ].levels[ levelID ].nodes.insert( nodeData )
	
	nodeID = XML_Loaded[ xmlID ].levels[ levelID ].nodes.length
	
	// Traverse attributes array and add attributes to this node, as long as the name property is not empty
	if nodeAttr.length > 0
		
		for a = 1 to nodeAttr.length
			
			if Len( nodeAttr[ a ].name ) > 0 then XML_Loaded[ xmlID ].levels[ levelID ].nodes[ nodeID ].attributes.insert( nodeAttr[ a ] )
			
		next a
		
	endif
	
	// if this is set to true, then this newly created node will be set as the active one. 
	// if you create a child node after this, it will be placed under this node.
	// if this parameter is set to false, then you will remain on the nesting level where this node has been created
	if setAsActive = XML_TRUE
		
		XML_Loaded[ xmlID ].level = XML_Loaded[ xmlID ].level + 1
		XML_Loaded[ xmlID ].node = nodeID
		
	endif
 
endfunction XML_TRUE

// Recursive method. Do not call manually, unless you are very familiar with the internal structure 
function XML_Array2XML_Traverse( id as integer , file as integer , l as integer , parent as string , parentUUID as string , useTabs as integer , rowSpacing as integer )
	
	local node as XML_Node
	local nodes as integer
	local attributes as integer
	local format as integer
	local data as string
	local nodeParent as string
	local nodeName as string
	local nodeUUID as string
	local nodeValue as string
	local tabs as string
	local vlnum as integer
	
	nodes = XML_Loaded[ id ].levels[ l ].nodes.length
	
	// Go through all nodes in this level
	for n = 1 to nodes
		
		data = ""
		
		node = XML_Loaded[ id ].levels[ l ].nodes[ n ]
	 
		
		// Nodes in this level can belong to various parent nodes. As such, only write the nodes that correspond to this parent
		if node.parent = parent and node.parentUUID = parentUUID
			
			nodeUUID = node.uuid
			nodeName = node.name
			nodeValue = node.value
			
			format = node.format
			attributes = node.attributes.length
 
			// add tabulation depending on nesting level (but avoid tabulation at root level)
			if useTabs = 1 
				
				tabs = XML_Add_Tabulation( l - 1 )
				if l = 1 then tabs = ""
				
			endif
			
			// If there is a comment for this node, add it one row above the node's opening tag
			if Len( node.comment ) > 0
				
				WriteLine( file , tabs + XML_CHAR_OPENING_BRACKET + XML_CHAR_COMMENT + "-- " + node.comment + " --" + XML_CHAR_CLOSING_BRACKET )
				
			endif
			
			// Start the node line by writing the opening bracket and the node name (result: <node)
			data = data + tabs + XML_CHAR_OPENING_BRACKET
			data = data + nodeName
			
			// If this node has any attributes, append them to the line (format: attr1="val" attr2="val" ... ; result: <node attr1="val attr2="val")
			if attributes > 0
				
				for a = 1 to attributes
			
					data = data + XML_CHAR_SPACE + node.attributes[ a ].name + XML_CHAR_ATTR_DELIMITER + XML_CHAR_QUOTATION + node.attributes[ a ].value + XML_CHAR_QUOTATION
					
				next a
				
			endif
			
			// Single line node without any values or child nodes; Therefore a closing slash is necessary (result: <node attr1="val" attr2="val" /)
			if format = 2
				
				data = data + XML_CHAR_CLOSING_SLASH
			
			// Single line node with a value but no child nodes; Therefore (result: <node attr1="val" attr2="val"> value </node)
			elseif format = 3
			
				data = data + XML_CHAR_CLOSING_BRACKET + node.value + XML_CHAR_OPENING_BRACKET + XML_CHAR_CLOSING_SLASH + nodeName
			
			endif
			
			// Add the closing bracket (>) (this is universal for any kind of node); Depending to node format the result may vary 
			// format = 1 -> <node attr1="val" ... > ; format = 2 -> <node attr1="val" ... /> ; format = 3 -> <node attr1="val" ...> value </node> 
			data = data + XML_CHAR_CLOSING_BRACKET
		
			// Finally write the data line to the XML file
			Writeline( file , data )
			
			// Add row spacing (if applicable) at the end of the line
			XML_Add_Row_Spacing( file , rowSpacing )
			
			// This is the main kind of node. A parent with possible attributes and child nodes within. This node extends on multiple lines
			if format = 1
				
				// If there is a value for this node, write it between the opening and closing tags. Also if useTabs = 1 add tabulation + one extra tab element
				if Len( nodeValue ) > 0
				 
					vlnum = node.valueLines.length
					
					// If the value is a long piece of text written on multiple lines, keep its structure when exporting. Otherwise, just write it in one line
					if vlnum > 1
						
						for x = 1 to vlnum-1
							
							WriteLine( file , tabs + XML_CHAR_TAB + Mid( nodeValue , node.valueLines[ x ] , node.valueLines[ x + 1 ] - node.valueLines[ x ] ) )
							
						next x
						
					else
					
						WriteLine( file , tabs + XML_CHAR_TAB + nodeValue )
					
					endif
					
					XML_Add_Row_Spacing( file , rowSpacing )
					
				endif
				
				// Recursively go through all child nodes within this parent node. This is a recursive method, which will continue to cycle through nests until it reaches the final nesting levels
				if l <  XML_Loaded[ id ].levels.length
					
					XML_Array2XML_Traverse( id , file , l + 1 , nodeName , nodeUUID , useTabs , rowSpacing )
			
				endif
				
				// Add the closing tag for this node (e.g. </node>)
				data = tabs + XML_CHAR_OPENING_BRACKET + XML_CHAR_CLOSING_SLASH + nodeName + XML_CHAR_CLOSING_BRACKET
				
				// Write the closing tag to the xml file
				Writeline( file , data )
				
				// Add row spacing after closing tag (if applicable)
				XML_Add_Row_Spacing( file , rowSpacing )
				
			endif
		
		endif
		
	next n
	
endfunction

function XML_Export( key as string , file as integer , useTabs as integer , rowSpacing as integer )
	
	local id as integer
	
	id = XML_Get_Index( key )
	
	if id = XML_FALSE then exitfunction XML_FALSE
	
	Writeline( file , '<?xml version="1.0" ?>' )
	
	XML_Array2XML_Traverse( id , file , 1 , XML_ROOT_NODE , XML_ROOT_NODE_UUID , useTabs , rowSpacing ) 
	
endfunction XML_TRUE

/*
 ----------------------------------- GET Functions [public] -----------------------------------
*/

function XML_Get_Index( xmlKey as string )
	
	local numXML as integer
	
	numXML = XML_Loaded.length

	// If there are no XML files loaded, exit and return -1
	if numXML = 0 then exitfunction XML_FALSE
		
	// Otherwise cycle through XML files and find the one corresponding to the xmlKey parameter
	for i = 1 to numXML
		
		// If an XML file has been found, exitfunction and return the file's index in the XML_Loaded array
		if XML_Loaded[ i ].key = xmlKey then exitfunction i
		
	next i
	
endfunction XML_FALSE

function XML_Get_Node_Attributes( xmlID as integer )
	
	local cLevel as integer
	local cNode as integer
	
	cLevel = XML_Loaded[ xmlID ].level
	cNode = XML_Loaded[ xmlID ].node
	 

endfunction XML_Loaded[ xmlID ].levels[ cLevel ].nodes[ cNode ].attributes


function XML_Get_Node_Attribute( xmlID as integer , attribute as string )
	
	local cLevel as integer
	local cNode as integer
	local aLen as integer
	
	cLevel = XML_Loaded[ xmlID ].level
	cNode = XML_Loaded[ xmlID ].node
	
	if cLevel < 1 or cNode < 1 then exitfunction XML_UNDEFINED
	
	aLen = XML_Loaded[ xmlID ].levels[ cLevel ].nodes[ cNode ].attributes.length 
	
	if aLen < 1 then exitfunction XML_UNDEFINED
 
	
	for a = 1 to aLen
	
		if XML_Loaded[ xmlID ].levels[ cLevel ].nodes[ cNode ].attributes[ a ].name = attribute
			
			exitfunction XML_Loaded[ xmlID ].levels[ cLevel ].nodes[ cNode ].attributes[ a ].value
			
		endif
		
	next a


endfunction XML_UNDEFINED

/*
 ----------------------------------- SET Functions [public] -----------------------------------
*/

function XML_Set_First_Child_Node( xmlID as integer )
	
	local cLevel as integer
	local cNode as integer
	
	cLevel = XML_Loaded[ xmlID ].level
	cNode = XML_Loaded[ xmlID ].node
	
	//If there are no more nesting levels beyond this point, exit function 
	if cLevel >= XML_Loaded[ xmlID ].levels.length then exitfunction XML_FALSE
	
	// Get the number of nodes within the next nesting level
	local nNum as integer
	nNum = XML_Loaded[ xmlID ].levels[ cLevel + 1 ].nodes.length
	
	// If there are no defined child nodes at this level, exit function
	if nNum < 1 then exitfunction XML_FALSE
 
	// Increase nesting level and set node to the first one
	XML_Loaded[ xmlID ].level = XML_Loaded[ xmlID ].level + 1
	XML_Loaded[ xmlID ].node = 1

	
endfunction XML_TRUE

function XML_Set_Parent_Node( xmlID as integer )
	
	local cLevel as integer
	local cNode as integer
	
	cLevel = XML_Loaded[ xmlID ].level
	cNode = XML_Loaded[ xmlID ].node
	
	//If this is the root node, exit function 
	if cLevel = 0 then exitfunction XML_FALSE
	
	// Decrease nesting level and set node to the first one
	XML_Loaded[ xmlID ].level = XML_Loaded[ xmlID ].level - 1
	XML_Loaded[ xmlID ].node = 1
	
endfunction XML_TRUE

function XML_Set_Next_Node( xmlID as integer )
	
	local cLevel as integer
	cLevel = XML_Loaded[ xmlID ].level
	
	if XML_Loaded[ xmlID ].node >= XML_Loaded[ xmlID ].levels[ cLevel ].nodes.length then exitfunction XML_FALSE
	
	XML_Loaded[ xmlID ].node = XML_Loaded[ xmlID ].node + 1
	
endfunction XML_TRUE

function XML_Set_Previous_Node( xmlID as integer )
	
	local cLevel as integer
	cLevel = XML_Loaded[ xmlID ].level
	
	if XML_Loaded[ xmlID ].node <= 0 then exitfunction XML_FALSE
	
	XML_Loaded[ xmlID ].node = XML_Loaded[ xmlID ].node - 1
	
endfunction XML_TRUE

 
 
/*
 ----------------------------------- Load XML from file -----------------------------------
*/


function XML_Load_File( xmlFile as string , key as string )
 
	if GetFileExists( xmlFile ) <> 1 then exitfunction 0
	
	local lineCount as integer
	local fLine as string
	local file as integer
	local lLen as integer
	local f2Char as string
	
	local temp as XML_Structure
	temp.key = key
	temp.level = 0
	temp.node = 0
	
	lineCount = 0
	 
	file = OpenToRead( xmlFile )
	
	// Traverse the xml file and filter out the unnecessary data
	while FileEOF( file ) = 0
		
		// Read the current line from the XML file
		fLine = ReadLine( file )
		
		// Trim all whitespaces at the ends of the string line to avoid errors when retreiving values
		fLine = XML_Trim( fLine )
		 
		lLen = Len( fLine )
		if lLen > 2
			
			// ASCII : 33 = ! (used to check for comments within the xml file and to disregard them)
			f2Char = Mid( fLine , 2 , 1 )
			
			// If the second character is different from a '!' (which indicates a comment), insert this row of data to XML_Loaded
			if f2Char <> XML_CHAR_COMMENT and f2Char <> XML_CHAR_HEADER

				lineCount = lineCount + 1
				temp.data.insert( fLine )
			
			elseif f2Char = XML_CHAR_HEADER
			
				temp.header = fLine
				
			endif
			 
			
		endif
		
	endwhile	
	
	CloseFile( file )
	 
	// If after filtering the data no proper xml structure exists, exitfunction 
	If lineCount = 0 then exitfunction 0
 
	XML_Loaded.insert( temp )
	
	local xmlID as integer
	xmlID = XML_Loaded.length
	
	XML_Traverse( xmlID , 1 , temp.data.length , 1 , XML_ROOT_NODE , XML_ROOT_NODE_UUID )
	
	XML_Loaded[ xmlID ].level = 1
	XML_Loaded[ xmlID ].node = 0
	 
	
endfunction XML_Loaded.length


function XML_Traverse( xmlID as integer , lStart as integer , lEnd as integer , nestLevel as integer , parent as string , parentUUID as string )
 
	local fChar as string
	local f2Char as string
	local l2Char as string
	local lChar as string
	local fLine as string
	local fLen as integer
	
	local bStr as string
	local bWord as string rem Block opening world
	local cWord as integer rem Block closing word
	local blockCheck as string
	local nodeRow as string[]
	local valueStack as string
	local nodeFormat as integer
	local uuid as string
	
	rem The two variables define the boundaries in the xml file for the respective nest's children
	local startPoint as integer
	local endPoint as integer

	local level as XML_Level
	local node as XML_Node
	local canContinue as integer
	
	local cOpeningBracket as string
	local cClosingBracket as string
	local cClosingSlash as string
	local numClosingBrackets as integer
	
	startPoint = 0
	endPoint = 0
	canContinue = 1
	
	// Expand levels if necessary
	if XML_Loaded[ xmlID ].levels.length < nestLevel   

		XML_Loaded[ xmlID ].levels.insert( level ) 
	
	endif
	
	cOpeningBracket = XML_CHAR_OPENING_BRACKET
	cClosingBracket = XML_CHAR_CLOSING_BRACKET
	cClosingSlash = XML_CHAR_CLOSING_SLASH
	 
	local vlines as integer[0]
	vlines.insert(1)
	
	local data as string[]
	
	for Line = lStart to lEnd
		
		bStr = XML_Loaded[ xmlID ].data[ Line ]
		fLen = Len( bStr )
 
		// Get the first, second , last and second last characters to check for xml blocks
		fChar = Left( bStr , 1 )
		f2Char = Mid( bStr , 2 , 1 )
		lChar = Right( bStr , 1 )
		l2Char = Mid( bStr , fLen - 1 , 1 )
		 
		// Text content within a block
		if fChar <> cOpeningBracket and lChar <> cClosingBracket
			
			valueStack = valueStack + bStr
			vlines.insert( Len( valueStack ) + 1 )
			
		endif
		
		// this is a block
		if fChar = cOpeningBracket and lChar = cClosingBracket and fLen >= 3
			
			data = XML_Parse_Tags( bStr )
			
			// Get the name tags of the block (opening and closing)
			bWord = data[ 1 ]
			cWord = FindStringReverse( bStr , bWord )
		 
 
			if canContinue = 1 then nodeRow = data
			
			// This is an opening block; there may be attributes and values here
			if f2Char <> cClosingSlash
				
				numClosingBrackets = FindStringCount( bStr , cClosingBracket )
				
				// This is certainly an opening block with possible child nodes
				if l2Char <> cClosingSlash and numClosingBrackets = 1
	  
					if canContinue = 1
						 
						startPoint = Line
						canContinue = 0
						blockCheck = bWord
						
					endif
					
				endif
				
				// This is a single line block with no value, but may have attributes
				if l2Char = cClosingSlash
				 
					nodeFormat = 2
					
				endif
				
				// This is a single line block with a value between the tags; may also have attributes
				if numClosingBrackets >= 2 and cWord > 0 and FindStringCount( bStr , cClosingSlash ) >= 1
			 
					nodeFormat = 3
					
				endif 

				
			endif
			
			// Generate a unique ID for this node (used to for parent-child referencing)
			uuid = XML_Generate_UUID() 
			
			// This is a closing tag; There shouldn't be any values or attributes on this line
			if f2Char = cClosingSlash and l2Char <> cClosingSlash and numClosingBrackets = 1 and bWord = blockCheck
				
				nodeFormat = 1 
				
				endPoint = Line
				
				canContinue = 1
				
				// Call this function recursively to go through all child nodes within this nest
				XML_Traverse( xmlID , startPoint + 1 , endPoint - 1 , nestLevel + 1 , blockCheck , uuid )
				
			endif
		 
			// If this flag = 1 then a node can be added to the xml document
			if canContinue = 1
				
				node.uuid = uuid
				node.name = bWord
				node.format = nodeFormat
				node.parent = parent
				node.parentUUID = parentUUID
				node.value = ""
				
				if nodeFormat = 3 
					
					node.value = XML_Parse_Value( bStr )
				
				elseif nodeFormat = 1 and Len( valueStack ) > 0
					
					node.value = valueStack
					node.valueLines = vlines
					valueStack = ""
					vlines.length = 0
					
				endif
				
				
				XML_Loaded[ xmlID ].levels[ nestLevel ].nodes.insert( node )
				
				// Go through any available attributes for this node and add them to the array element
				XML_Parse_Attributes( xmlID , nestLevel , XML_Loaded[ xmlID ].levels[ nestLevel ].nodes.length , nodeRow )
			
			endif
 
			
		endif
  
		
	next Line
	 
	
endfunction


function XML_Parse_Attributes( xmlID as integer , nodeLevel as integer , nodeIndex as integer , attributes as string[] )
	
	local aData as string
	local attrName as string
	local attrRetval as string
	local avLen as integer
	local attribute as XML_Attribute
	
	numAttr = attributes.length
	
	if numAttr <= 1 then exitfunction
		 
	for attr = 2 to numAttr
		
		aData = attributes[ attr ]
		
		// Get the name and value of the attribute
		attrName = GetStringToken( aData , XML_CHAR_ATTR_DELIMITER , 1 )
		attrRetval = GetStringToken( aData , XML_CHAR_ATTR_DELIMITER , 2 )
		
		avLen = Len( attrRetval )
 
		// Remove any pairs of quotation marks
		If avLen >= 2  
			
			attrRetval = Mid( attrRetval , 2 , avLen - 2 )
			
		Endif
		
		// After removing quotation marks, the value in the string may have whitespace on both ends. Remove it
		attrRetval = XML_Trim( attrRetval )
		
		attribute.name = attrName
		attribute.value = attrRetval
		
		XML_Loaded[ xmlID ].levels[ nodeLevel ].nodes[ nodeIndex ].attributes.insert( attribute )
		
	next attr	
 
endfunction


function XML_Remove( id as integer )
	
	if id > XML_Loaded.length then exitfunction 0
	
	XML_Loaded.remove( id )
	
endfunction 1

/*
 ----------------------------------- String manipulation -----------------------------------
*/
 
 
function XML_Parse_Value( line as string )
	
	local val as string
	local charcount as integer
	local char as string
	local cOpeningBracket as string
	local cClosingBracket as string
	 
	cOpeningBracket = XML_CHAR_OPENING_BRACKET
	cClosingBracket = XML_CHAR_CLOSING_BRACKET
	
	val = GetStringToken( line , cOpeningBracket , CountStringTokens( line , cOpeningBracket ) - 1 )
 
	charcount = Len( val )
	
	for c = charcount to 1 step -1
		
		char = Mid( val , c  , 1 )
		
		if char = cClosingBracket
			
			exitfunction Right( val , charcount - c  )
			
		endif
		
	next c
	
endfunction val


function XML_Parse_Tags( line as string )

	local tagNum as integer
	local c as string
	local data as string[ 0 ]

	
	local qMarks as integer
	local attrNum as integer
	local attrStr as string
	local cSeq as integer
	
	split_l$ = GetStringToken( line , XML_CHAR_CLOSING_BRACKET , 1 )
	split_len = Len( split_l$ )
	
	// Start at least from the second character (to avoid going through the opening bracket)
	for char = 2 to split_len
		
		c = Mid( split_l$ , char , 1 )
		
		
		rem If its not a space or TAB
		if ( c <> XML_CHAR_SPACE and c <> XML_CHAR_TAB and c <> XML_CHAR_OPENING_BRACKET and c <> XML_CHAR_CLOSING_BRACKET and c <> XML_CHAR_CLOSING_SLASH ) or ( qMarks > 0 and qMarks <= 2 )
			
			if cSeq = 0 then cSeq = 1
			attrStr = attrStr + c
			
			If c = XML_CHAR_QUOTATION then qMarks = qMarks + 1
			If qMarks = 2 then qMarks = 0
			
		endif
			
		rem If it is a space or a TAB
		If ( ( c = XML_CHAR_SPACE or c = XML_CHAR_TAB ) or c = XML_CHAR_QUOTATION or char = split_len ) and qMarks = 0 and cSeq = 1
		 
			//debug$ = debug$ + attrStr + "|"
			data.insert( attrStr )
			attrNum = attrNum + 1
			attrStr = ""
 
			cSeq = 0
			
		endif
	 
		 
	next char
	
	 
	
endfunction data
 
 
 
function XML_Trim( strVar as string )
	
	local strRes as string
	local strLen as integer

	strLen = Len( strVar )
	if strLen = 0 then exitfunction strVar
	
	local trimmed as string
	
	trimmed = TrimString( strVar , XML_CHAR_SPACE + XML_CHAR_TAB )
 
 
endfunction trimmed

function XML_Add_Row_Spacing( file as integer , rowSpacing as integer )
	
	if rowSpacing <= 0 then exitfunction
 	
	for r = 1 to rowSpacing
		
		Writeline( file , "" )
		
	next r
	
endfunction

function XML_Add_Tabulation( amount )
	
	local tabs as string
	
	if amount = 0 then exitfunction tabs
 
	for tab = 1 to amount
		
		tabs = tabs + XML_CHAR_TAB
		
	next tab
	
endfunction tabs
