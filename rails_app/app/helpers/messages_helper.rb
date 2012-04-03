module MessagesHelper
  def url_maker(string)
    string.gsub(/(?<url>\b([\d\w\.\/\+\-\?\:]*)((ht|f)tp(s|)\:\/\/|[\d\d\d|\d\d]\.[\d\d\d|\d\d]\.|www\.|\.tv|\.ac|\.com|\.edu|\.gov|\.int|\.mil|\.net|\.org|\.biz|\.info|\.name|\.pro|\.museum|\.co)([\d\w\.\/\%\+\-\=\&amp;\?\:\\\&quot;\'\,\|\~\;]*)\b)/i,'<a href="http://\k<url>" target="_blank" class="url_in_box">\k<url></a>').gsub(/http\:\/\/http\:\/\//,'http://')
  end
end
