(define (domain urbantraffic)
;; (:requirements :typing :fluents :time :timed-initial-literals :duration-inequalities :adl)

(:types junction link stage configuration)

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
(dec ?i - junction ?p - stage)
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
        (endcycle ?i ?p)
        (availableconf ?i ?c2)
        (activeconf ?i ?c1)
        (not (activeconf ?i ?c2))
    )
    :effect (and 
        (not (activeconf ?i ?c1)) 
        (activeconf ?i ?c2)
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
        (dec ?i ?p)
        )
)

(:event decrease_greentime
    :parameters (?p - stage ?i - junction)
    :precondition (and
        (dec ?i ?p)
        (> (greentime ?i) 0)
    )
    :effect (and
        (decrease (greentime ?i) (greentime ?i))
        (not (dec ?i ?p))
    )
)

(:event decrease_intergreen
    :parameters (?p - stage ?i - junction)
    :precondition (and
        (dec ?i ?p)
        (> (intertime ?i) 0)
    )
    :effect (and
        (decrease (intertime ?i) (intertime ?i))
        (not (dec ?i ?p))
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
        (dec ?i ?p)
	)
)

)
