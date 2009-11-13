Extension { #name : #PPParser }

{ #category : #'*petitanalyzer-querying' }
PPParser >> firstSet [
	"Answer the first-set of the receiver. Note, this implementation is inefficient when called on different receivers of the same grammar, instead use #firstSets to calculate the first-sets at once."
	
	^ self firstSets at: self
]

{ #category : #'*petitanalyzer-querying' }
PPParser >> firstSets [
	"Answer a dictionary with all the parsers reachable from the receiver as key and their first-set as value. The first-set of a parser is the list of terminal parsers that begin the parser derivable from that parser."
	
	| firstSets |
	firstSets := IdentityDictionary new.
	self allNodesDo: [ :each | 
		firstSets at: each put: (each isTerminal
			ifTrue: [ IdentitySet with: each ]
			ifFalse: [ IdentitySet new ]) ].
	[	| changed tally |
		changed := false.
		firstSets keysAndValuesDo: [ :parser :first |
			tally := first size.
			parser firstSets: firstSets into: first.
			changed := changed or: [ tally ~= first size ] ].
		changed ] whileTrue.
	^ firstSets
]

{ #category : #'*petitanalyzer-private' }
PPParser >> firstSets: aFirstDictionary into: aSet [
	"PRIVATE: Try to add additional elements to the first-set aSet of the receiver, use the incomplete aFirstDictionary."

	self children do: [ :parser | aSet addAll: (aFirstDictionary at: parser) ]
]

{ #category : #'*petitanalyzer-querying' }
PPParser >> followSet [
	"Answer the follow-set of the receiver starting at the receiver. Note, this implementation is inefficient when called on different receivers of the same grammar, instead use #followSets to calculate the follow-sets at once."

	^ self followSets at: self
]

{ #category : #'*petitanalyzer-querying' }
PPParser >> followSets [
	"Answer a dictionary with all the parsers reachable from the receiver as key and their follow-set as value. The follow-set of a parser is the list of terminal parsers that can appear immediately to the right of that parser."
	
	| current previous continue firstSets followSets |
	current := previous := 0.
	firstSets := self firstSets.
	followSets := IdentityDictionary new.
	self allNodesDo: [ :each | followSets at: each put: IdentitySet new ].
	(followSets at: self) add: PPEpsilonParser new.
	[	followSets keysAndValuesDo: [ :parser :follow |
			parser 
				followSets: followSets
				firstSets: firstSets
				into: follow ].
		current := followSets
			inject: 0
			into: [ :result :each | result + each size ].
		continue := previous < current.
		previous := current.
		continue ] whileTrue.
	^ followSets
]

{ #category : #'*petitanalyzer-private' }
PPParser >> followSets: aFollowDictionary firstSets: aFirstDictionary into: aSet [
	"PRIVATE: Try to add additional elements to the follow-set aSet of the receiver, use the incomplete aFollowDictionary and the complete aFirstDictionary."
	
	self children do: [ :parser | (aFollowDictionary at: parser) addAll: aSet ]
]

{ #category : #'*petitanalyzer-testing' }
PPParser >> isNullable [
	"Answer true if the receiver is a nullable parser, e.g. it can successfully parse nothing."
	
	^ false
]

{ #category : #'*petitanalyzer-testing' }
PPParser >> isTerminal [
	"Answer true if the receiver is a terminal parser, that means it does not delegate to any other parser."
	
	^ false
]

{ #category : #'*petitanalyzer-querying' }
PPParser >> leftRecursion [
	"Answer an ordered collection with a left-recursive cycle starting at the receiver, or an empty collection if no such cycle could be detected."
	
	| result |
	result := OrderedCollection new.
	self leftRecursion: result firstSets: self firstSets answer: [ ^ result ].
	^ result
]

{ #category : #'*petitanalyzer-private' }
PPParser >> leftRecursion: anOrderedCollection firstSets: aDictionary answer: anAnswerBlock [
	"PRIVATE: Try to find a cycle, where anOrderedCollection contains the previously visited parsers. The method returns quickly when the receiver is a terminal, terminals cannot be part of a cycle. If anOrderedCollection already contains the receiver, then we are in a cycle and need to return. If the receiver is the first element, we actually found a receiver we are interested in."

	self isTerminal
		ifTrue: [ ^ self ].
	(anOrderedCollection includes: self) ifTrue: [
		anOrderedCollection first = self
			ifTrue: [ anAnswerBlock value ]
			ifFalse: [ ^ self ] ].
	anOrderedCollection addLast: self.
	self children 
		do: [ :each | each leftRecursion: anOrderedCollection firstSets: aDictionary answer: anAnswerBlock ].
	anOrderedCollection removeLast
]