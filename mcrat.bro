##! Detects McRAT C&C traffic after successful exploitation of CVE-2013-1493.
##! More details by FireEye: http://bit.ly/cve-2013-1493.
@load ./http

module Malware;

export {
  redef enum Notice::Type += {
    ## McRAT C&C activity.
    McRAT_CC_Activity
  };
}

event http_request(c: connection, method: string, original_URI: string,
    unescaped_URI: string, version: string)
  {
    if ( method == "POST" && unescaped_URI == "/59788582" && version == "1.0" )
      c$http$malware = unescaped_URI;
  }

event http_all_headers(c: connection, is_orig: bool, hlist: mime_header_list)
  {
    if ( ! is_orig || ! c$http?$malware )
      return;

    for ( i in hlist )
      {
      local name = hlist[i]$name;
      local value = hlist[i]$value;
      if ( (name == "CONTENT-LENGTH" && value != "44" ) ||
           ( name == "PRAGMA" && value != "no-cache" )  ||
           ( name == "HOST" && /110\.[0-9]+\.55\.187/ !in value ) )
        {
        delete c$http$malware;
        return;
        }
      }

    NOTICE([$note=McRAT_CC_Activity,
           $msg=fmt("McRAT C&C activity: POST %s", c$http$malware),
           $conn=c]);

    delete c$http$malware;
  }
