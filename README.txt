Wikipedia contains a large number of articles which are written in many languages. This tool aims
to retrieve comparable documents from Wikipedia in order to build comparable corpora. Different
to a crawling tool, this tool make use of available Wikipedia dump data (available for download
in https://dumps.wikimedia.org) which contains extensive information of Wikipedia documents, 
including links between bilingual articles. A subset of Wikipedia dump data which was downloaded
in September 2010 has been included in this tool for testing reasons. Should different data be 
needed for further evaluation, the process of downloading them can be found in the Wikimedia link
above and therefore are not described in the tool's description.

This tool works by analysing the contents of Wikipedia documents, specifically looking for documents
which contain any information overlap (anchors or words). Documents which are considered to be 
comparable are extracted and used to build comparable corpora. More information regarding the 
retrieval methods are available in D3.4.

To run this tool, please use the following syntax:

perl WikipediaRetrieval.pl --source [sourceLang] --target [targetLang] –-alignment [alignmentFile] 
  –-sourceFolder [folderPathForSourceDocs] -–targetFolder [folderPathForTargetDocs] –-output [outputFolder]

For example:

perl WikipediaRetrieval.pl --source lv --target en --alignment lv_en_small.txt --sourceFolder
  lv --targetFolder en --output C:\ComparableCorpora\

If you have any questions or problems while running this tool, please contact Monica Paramita
(m.paramita@sheffield.ac.uk).

=========================================================================================================

Notes:
1) When alignment file or documents are not available, you can run WikipediaExtractor.pl using this command
by previously downloading the necessary database dump from Wikipedia (please refer to information in D3.6):

perl WikipediaExtractor.pl --source [sourceLang] --target [targetLang] -–sourcePage [pageOfSourceLang] 
  --targetPage [pageOfTargetLang] --output [outputFolder]

For example:

perl WikipediaExtractor.pl --source lv --target en --sourcePage lvwiki-20111022-pages-articles.xml
  --targetPage enwiki-20111007-pages-articles.xml --output C:\InitialCorpus\

2) The alignment file lv_en_small.txt only contains 200 documents for testing reason. Please note that 
this script will produce error messages if the listed documents (included in alignment file) are not available.
