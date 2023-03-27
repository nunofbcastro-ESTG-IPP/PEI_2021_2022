module namespace local = 'http://basex.org/examples/web-page';

declare default element namespace 'http://www.trabalhoPEI.pt/SubmissionRules';
declare namespace inspectionsNameSpace = 'http://www.trabalhoPEI.pt/InspectionsRules';
declare namespace violationsListNameSpace = 'http://www.trabalhoPEI.pt/ViolationsListRules';

declare function local:getViolationsList($xml) as element()*{
  for $x in $xml/violationsListNameSpace:violation
  return $x
};

declare function local:validar-violacao($violacao, $xml) as element()*{
  for $x in $xml//violationsListNameSpace:violation
  where $x/violationsListNameSpace:violation_code = $violacao/inspectionsNameSpace:violation_code
  return $violacao
};

declare function local:getViolations($violations, $xml) as element()*{
  for $x in $violations/inspectionsNameSpace:violation
  let $violacao := local:validar-violacao($x, $xml)
  return $violacao
};

declare function local:validateInspectionDate ($date as xs:dateTime, $xml) as xs:integer{
  let $week := $xml//submissionInfo/week
  let $submissionDate := $xml//submissionInfo/submissionDate
  return if($date >= xs:dateTime($week) and $date < xs:dateTime($submissionDate)) then (
   1
  )else (0)
};

declare function local:getInspections($xml) as element()*{  
  for $x in $xml//inspections/inspectionsNameSpace:inspection
  return if(local:validateInspectionDate ($x/inspectionsNameSpace:date, $xml) = 1) then (
     copy $validatedX := $x
     modify (replace node $validatedX//inspectionsNameSpace:violations with <violations>{local:getViolations($x//inspectionsNameSpace:violations, $xml)}</violations>)
     return$validatedX 
  )
    
};

declare function local:getSubmissionInfo($submission) as xs:integer{
  let $diff :=  xs:date(xs:dateTime($submission/submissionDate)) - xs:date(xs:dateTime($submission/week))
  return if($diff = xs:dayTimeDuration("P6D")) then (
    if($submission/year = fn:year-from-dateTime($submission/week)) then(
      1
    )
  )else (0)
};

declare %rest:path("addSubmission")
  %rest:POST("{$xml}")
  %rest:consumes('application/xml')
  updating
  
  function local:add($xml as item()) {
    let $xsd:= "./xsd/SubmissionRules.xsd"
    return validate:xsd($xml, $xsd),
    if(local:getSubmissionInfo($xml//submissionInfo) = 1) then (
      update:output("Insert successful."), 
      if(db:exists("safefood")) then (
             db:add("safefood", 
              <submission>
                  {$xml//submissionInfo}
                  <inspections>{local:getInspections($xml)}</inspections>
                  <violationsList>{local:getViolationsList($xml//violationsList)}</violationsList>
              </submission>, 
              concat("Submission_", $xml//submissionInfo/partner/text(), "_", xs:date(xs:dateTime($xml//submissionInfo/week)), ".xml"))
           )else (
              db:create("safefood", 
              <submission>
                  {$xml//submissionInfo}
                  <inspections>{local:getInspections($xml)}</inspections>
                  <violationsList>{local:getViolationsList($xml//violationsList)}</violationsList>
              </submission>, 
              concat("Submission_", $xml//submissionInfo/partner/text(), "_", xs:date(xs:dateTime($xml//submissionInfo/week)), ".xml"))
           )
     ) else (update:output("Invalid Submission."))
};

declare %rest:path("updateSubmission")
  %rest:POST("{$xml}")
  %rest:query-param("fileName", "{$fileName}")
  %rest:consumes('application/xml')
  updating
  
  function local:update($xml as item(), $fileName as xs:string){
    let $xsd:= "./xsd/SubmissionRules.xsd"
    return validate:xsd($xml, $xsd),
    if(local:getSubmissionInfo($xml//submissionInfo) = 1) then (
      update:output("Update successful."), 
      if(db:exists("safefood")) then (
             db:replace("safefood", $fileName,
              <submission>
                  {$xml//submissionInfo}
                  <inspections>{local:getInspections($xml)}</inspections>
                  <violationsList>{local:getViolationsList($xml//violationsList)}</violationsList>
              </submission>)
       )else(update:output("No database available! Invalid Update."))
     )else (update:output("Invalid data! Invalid Update."))
};