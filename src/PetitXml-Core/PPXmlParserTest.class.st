Class {
	#name : #PPXmlParserTest,
	#superclass : #PPCompositeParserTest,
	#category : #'PetitXml-Tests'
}

{ #category : #accessing }
PPXmlParserTest class >> packageNamesUnderTest [
	^ #('PetitXml')
]

{ #category : #accessing }
PPXmlParserTest class >> resources [
	^ Array with: PPXmlResource
]

{ #category : #utilities }
PPXmlParserTest >> assertAttributeInvariant: aNode [
	"Assert that the attributes can be properly accessed."
	
	aNode nodesDo: [ :node |
		node isElement ifTrue: [
			node attributes do: [ :attr |
				self assert: (node attributeAt: attr name localName) = attr value.
				self assert: (node attributeNodeAt: attr name localName) = attr ].
			node attributes isEmpty ifTrue: [ 
				self assert: (node attributeAt: 'foo') isNil.
				self assert: (node attributeNodeAt: 'foo') isNil ] ] ]
]

{ #category : #utilities }
PPXmlParserTest >> assertCopyInvariant: aNode [
	"Assert that the copy is equivalent to the original."
	
	| copy |
	copy := aNode copy.
	self deny: aNode == copy.
	self assert: aNode = copy.
	self assert: copy = aNode
]

{ #category : #utilities }
PPXmlParserTest >> assertEquivalentInvariant: aNode [
	"Assert that each node is equivalent to itself."
	
	aNode nodesDo: [ :node | 
		self assert: node = node.
		self assert: node hash = node hash ]
]

{ #category : #utilities }
PPXmlParserTest >> assertInvariants: aDocumentNode [
	"Assert that anXmlNode is properly setup.."
	
	self assertCopyInvariant: aDocumentNode.
	self assertEquivalentInvariant: aDocumentNode.
	self assertRootInvariant: aDocumentNode.
	self assertParentInvariant: aDocumentNode.
	self assertNavigationInvariant: aDocumentNode.
	self assertAttributeInvariant: aDocumentNode.
	self assertTypeInvariant: aDocumentNode
]

{ #category : #utilities }
PPXmlParserTest >> assertNameInvariant: aXmlName [
	"Assert the name invariants."
	
	self assert: (aXmlName localName notNil and: [ aXmlName localName notEmpty and: [ aXmlName qualifiedName endsWith: aXmlName localName ] ]).
	self assert: (aXmlName namespacePrefix isNil or: [ aXmlName namespacePrefix notEmpty and: [ aXmlName qualifiedName beginsWith: aXmlName namespacePrefix ] ]).
	self assert: (aXmlName uri isNil or: [ aXmlName uri notEmpty ]).
	
	self assert: aXmlName = aXmlName.
	self assert: aXmlName copy = aXmlName.
	self assert: aXmlName = aXmlName copy.
	
	self assert: aXmlName printString isString
	
]

{ #category : #utilities }
PPXmlParserTest >> assertNavigationInvariant: aXmlNode [
	"Assert that the firstChild, lastChild, previousSibling, nextSibling are properly setup."

	| current children |
	aXmlNode nodesDo: [ :node |

		" forward "
		current := node firstChild.
		children := OrderedCollection withAll: node children.
		[ current isNil ] whileFalse: [
			self assert: children notEmpty.
			self assert: children removeFirst == current.
			current := current nextSibling ].
		self assert: children isEmpty.
		
		" backward "
		current := node lastChild.
		children := OrderedCollection withAll: node childNodes.
		[ current isNil ] whileFalse: [
			self assert: children notEmpty.
			self assert: children removeLast == current.
			current := current previousSibling ].
		self assert: children isEmpty ]
]

{ #category : #utilities }
PPXmlParserTest >> assertParentInvariant: anXmlNode [
	"Assert that the children-parent relationship is properly set."
	
	anXmlNode nodesDo: [ :node |
		node children 
			do: [ :child | self assert: child parent == node ].
		node attributes
			do: [ :child | self assert: child parent == node ].
		node isDocument 
			ifTrue: [ self assert: node parent isNil ] ]
]

{ #category : #utilities }
PPXmlParserTest >> assertParseInvariant: aString [
	"Assert that aString can be parsed, serialized and parsed again to the same tree."

	| tree stream string |
	tree := self parse: aString.
	self
		deny: tree isPetitFailure
		description: tree printString.
	stream := WriteStream on: String new.
	tree printXmlOn: stream.
	string := stream contents.
	self
		assert: (self parse: string) = tree
		description: 'Parse invariant not satisifed'.
	self assertInvariants: tree
]

{ #category : #utilities }
PPXmlParserTest >> assertRootInvariant: aDocumentNode [
	"Assert that anXmlNode is the root of the tree."
	
	self assert: (aDocumentNode childNodes includes: aDocumentNode rootElement).
	aDocumentNode nodesDo: [ :node |
		self assert: node root == aDocumentNode.
		self assert: node document == aDocumentNode ]
]

{ #category : #utilities }
PPXmlParserTest >> assertTypeInvariant: aNode [
	"Assert that each node is one of the standard types."
	
	| types |
	aNode nodesDo: [ :node |
		types := Set new.
		#(isAttribute isComment isDoctype isDocument isElement isProcessing isText) do: [ :each |
			(node perform: each)
				ifTrue: [ types add: each ] ].
		self assert: types size = 1.
		(node isElement or: [ node isAttribute ])
			ifTrue: [ self assertNameInvariant: node name ] ]
]

{ #category : #accessing }
PPXmlParserTest >> parserClass [
	^ PPXmlParser
]

{ #category : #accessing }
PPXmlParserTest >> resource [
	^ PPXmlResource current
]

{ #category : #'testing-other' }
PPXmlParserTest >> testInstantiation [
	self should: [ PPXmlAttribute new ] raise: Error.
	self should: [ PPXmlComment new ] raise: Error.
	self should: [ PPXmlDoctype new ] raise: Error.
	self should: [ PPXmlProcessing new ] raise: Error.
	self should: [ PPXmlText new ] raise: Error.
	self should: [ PPXmlDocument new ] raise: Error.
	self should: [ PPXmlElement new ] raise: Error
]

{ #category : #testing }
PPXmlParserTest >> testParseAllXml [
	self resource allXmlDefinitions 
		do: [ :each | self assertParseInvariant: each ]
]

{ #category : #'testing-parsing' }
PPXmlParserTest >> testParseComment [
	self assertParseInvariant: '<?xml version="1.0" encoding="UTF-8"?><schema><!-- comment --></schema>' 
]

{ #category : #'testing-parsing' }
PPXmlParserTest >> testParseCommentWithXml [
	self assertParseInvariant: '<?xml version="1.0" encoding="UTF-8"?><schema><!-- <foo></foo> --></schema>' 
]

{ #category : #'testing-parsing' }
PPXmlParserTest >> testParseComplicated [
	self assertParseInvariant: '<?xml foo?>
<foo>
	<bar a="fasdfasdf">
		<zork/>
		<zonk/>
	</bar>
	<!-- with comment -->
</foo>' 
]

{ #category : #'testing-parsing' }
PPXmlParserTest >> testParseDoctype [
	self assertParseInvariant: '<?xml version="1.0" encoding="UTF-8"?>
	<!DOCTYPE freaking <schema> [ <!-- schema --> ]  >
	<schema></schema>'
]

{ #category : #'testing-parsing' }
PPXmlParserTest >> testParseEmptyElement [
	self assertParseInvariant: '<?xml version="1.0" encoding="UTF-8"?><schema/>' 
]

{ #category : #'testing-parsing' }
PPXmlParserTest >> testParseNamespace [
	self assertParseInvariant: '<?xml version="1.0" encoding="UTF-8"?><xs:schema></xs:schema>' 
]

{ #category : #'testing-parsing' }
PPXmlParserTest >> testParseSimple [
	self assertParseInvariant: '<?xml version="1.0" encoding="UTF-8"?><schema></schema>' 
]

{ #category : #'testing-parsing' }
PPXmlParserTest >> testParseSimpleAttribute [
	self assertParseInvariant: '<?xml version="1.0" encoding="UTF-8"?><schema foo="bar"></schema>' 
]

{ #category : #'testing-parsing' }
PPXmlParserTest >> testParseSimpleAttributeWithSingleQuote [
	self assertParseInvariant: '<?xml version="1.0" encoding="UTF-8"?><schema foo=''bar''></schema>' 
]

{ #category : #'testing-parsing' }
PPXmlParserTest >> testParseWithWhitsepaceAfterProlog [
	self assertParseInvariant: '<?xml version="1.0" encoding="UTF-8"?>
	<schema></schema>
' 
]

{ #category : #'testing-other' }
PPXmlParserTest >> testQualifiedName [
	| name |
	name := PPXmlName name: 'prefix:tag'.
	self assertNameInvariant: name.
	self assert: name localName = 'tag'.
	self assert: name namespacePrefix = 'prefix'.
	self assert: name qualifiedName = 'prefix:tag'.
	self assert: name uri isNil
]

{ #category : #'testing-other' }
PPXmlParserTest >> testUnqualifiedName [
	| name |
	name := PPXmlName name: 'tag'.
	self assert: name localName = 'tag'.
	self assert: name namespacePrefix isNil.
	self assert: name qualifiedName = 'tag'.
	self assert: name uri isNil
]

{ #category : #'testing-other' }
PPXmlParserTest >> testUriName [
	| name |
	name := PPXmlName name: 'prefix:tag' uri: 'http://www.lukas-renggli.ch/'.
	self assertNameInvariant: name.
	self assert: name localName = 'tag'.
	self assert: name namespacePrefix = 'prefix'.
	self assert: name qualifiedName = 'prefix:tag'.
	self assert: name uri = 'http://www.lukas-renggli.ch/'
]