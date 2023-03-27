module namespace local = 'http://basex.org/examples/web-page';
declare default element namespace 'http://www.trabalhoPEI.pt/SubmissionRules';

declare 
  %rest:path("getPartners")
  %rest:query-param("date", "{$date}")
    
function local:getPartners($date as item())
{
  <partners>{
  for $submission in db:open("safefood")//submissionInfo
  where xs:date(xs:dateTime($submission/week)) =  xs:date($date)
  return <partner>{$submission/partner/text()}</partner>
  }</partners>
};