module namespace page = 'http://basex.org/exemples/web-page';

declare default element namespace 'http://www.trabalhoPEI.pt/SubmissionRules';

declare
  %rest:path("export_xml")
  %rest:GET
function page:export_xml(){
  let $submissions := db:open("safefood")//submission
  return 
  (
    <submissions>
      {$submissions}
    </submissions>
  )
};