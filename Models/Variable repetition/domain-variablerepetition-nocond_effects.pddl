(define (domain urbantraffic)

(:types junction link stage configuration limit)

(:predicates 
(controllable ?i - junction)
(inter ?p - stage)
(active ?p - stage)
(next ?p ?p1 - stage)
(trigger ?i - junction)
(contains ?i - junction ?p - stage)
(endcycle ?i - junction ?p - stage)
(activeconf ?i - junction ?c - configuration)
(availableconf ?i - junction ?c - configuration)
(configurable ?i - junction ?p - stage)
(checkable ?i - junction ?p - stage)
)

(:functions 
(turnrate ?x - stage ?r1 - link  ?r2 - link) 
(interlimit ?p - stage)
(occupancy ?r - link) 
(capacity ?r - link)  
(confgreentime ?p - stage ?c - configuration )
(greentime ?i - junction)
(intertime ?i - junction)
(counter ?r - link)
(countcycle ?i - junction)
(cyclelimit ?i - junction)
(conflimit ?i - junction)
)

;; the maximum time limit for green has been reached, but no need to restart token!
(:event confgreenreached
 :parameters (?p - stage ?i - junction ?c - configuration)
 :precondition (and 
	(active ?p) (contains ?i ?p)
    (activeconf ?i ?c)
	(>= (greentime ?i) (confgreentime ?p ?c))
	)
  :effect (and
	(trigger ?i)
	)
)

;; process that keeps the green/intergreen on, and updates the greentime value
(:process keepgreen
:parameters (?p - stage ?i - junction ?c - configuration)
:precondition (and 
		(active ?p) (contains ?i ?p)
      (activeconf ?i ?c)
    (< (greentime ?i) (confgreentime ?p ?c))
)
:effect (and
		(increase (greentime ?i) (* #t 1 ) )
))

;;allows car to flow if the corresponding green is on
(:process flowrun_green
:parameters (?p - stage ?r1 ?r2 - link)
:precondition (and 
		(active ?p)
		(> (occupancy ?r1) 0.0)
		(> (turnrate ?p ?r1 ?r2) 0.0)
		(< (occupancy ?r2) (capacity ?r2))
)
:effect (and
		(increase (occupancy ?r2) (* #t (turnrate ?p ?r1 ?r2)))
		(decrease (occupancy ?r1) (* #t (turnrate ?p ?r1 ?r2)))
    (increase (counter ?r2) (* #t (turnrate ?p ?r1 ?r2)))
))

;; let the planner in control of changing configuration at the end of the phase cycle
(:action changeConfiguration
    :parameters (?p - stage ?i - junction ?c1 ?c2 - configuration)
    :precondition (and
        (inter ?p)
        (controllable ?i)
        (>= (countcycle ?i) (cyclelimit ?i))
        (endcycle ?i ?p)
        (availableconf ?i ?c2)
        (activeconf ?i ?c1)
        (not (activeconf ?i ?c2))
    )
    :effect (and 
        (not (activeconf ?i ?c1))
        (activeconf ?i ?c2)
        (assign (countcycle ?i) 0)
        (configurable ?i ?p)
    )
)

(:action changeLimit
    :parameters (?p - stage ?i - junction ?l - limit)
    :precondition (and 
        (inter ?p)
        (configurable ?i ?p)
        (not (= (cyclelimit ?i) (conflimit ?l)))
     )
    :effect (and 
      (assign (cyclelimit ?i) (conflimit ?l))
      (not (configurable ?i ?p))
    )
)


(:event trigger-inter
:parameters (?p - stage ?i - junction)
 :precondition (and
        (trigger ?i)
        (active ?p) (contains ?i ?p)
        )
  :effect (and
        (not (trigger ?i))
        (not (active ?p))
        (inter ?p)
	    (assign (greentime ?i) 0)
    )
)


(:process keepinter
  :parameters (?p - stage ?i - junction)
  :precondition (and 
      (inter ?p) (contains ?i ?p)
      (< (intertime ?i) (interlimit ?p)  )
   )
   :effect (and
      (increase (intertime ?i) (* #t 1 ) )
   ))

(:event trigger-change
:parameters (?p ?p1 - stage ?i - junction)
 :precondition (and 
	(inter ?p) (contains ?i ?p)
        (next ?p ?p1)
        (>= (intertime ?i) (- (interlimit ?p) 0.1)  )
	)
  :effect (and
	(not (inter ?p))
        (active ?p1)
	(assign (intertime ?i) 0)
    (checkable ?i ?p1)
    (checkable ?i ?p)
))

(:event increaseCycle
    :parameters (?p - stage ?i - junction)
    :precondition (and
        (endcycle ?i ?p)
        (active ?p)
        (checkable ?i ?p)
    )
    :effect (and
        (increase (countcycle ?i) 1)
        (not (checkable ?i ?p))
    )
)

(:event disableConf
    :parameters (?p - stage ?i - junction)
    :precondition (and
        (checkable ?i ?p)
        (not (active ?p))
        (endcycle ?i ?p)
    )
    :effect (and
        (not (configurable ?i ?p))
        (not (checkable ?i ?p))
    )
)



)


