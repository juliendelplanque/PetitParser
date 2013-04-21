"
A parser that accepts a single literal object, such as a character. This is the same as the predicate parser 'PPPredicateParser expect: literal' but slightly more efficient.
"
Class {
	#name : #PPLiteralObjectParser,
	#superclass : #PPLiteralParser,
	#category : #'PetitParser-Parsers'
}

{ #category : #operators }
PPLiteralObjectParser >> caseInsensitive [
	"Answer a parser that can parse the receiver case-insensitive."
	
	literal asUppercase = literal asLowercase ifTrue: [ ^ self ].
	^ PPPredicateObjectParser on: [ :value | literal sameAs: value ] message: message
]

{ #category : #operators }
PPLiteralObjectParser >> negate [
	^ (PPPredicateObjectParser expect: literal message: message) negate
]

{ #category : #parsing }
PPLiteralObjectParser >> parseOn: aStream [
	^ (aStream atEnd not and: [ literal = aStream uncheckedPeek ])
		ifFalse: [ PPFailure message: message at: aStream position ]
		ifTrue: [ aStream next ]
]