CREATE OR REPLACE PROCEDURE send_sms(p_user     IN VARCHAR2, -- Twilio user name
                                     p_pass     IN VARCHAR2, -- Twilio password
                                     p_from     IN VARCHAR2, -- Twilio From phone number
                                     p_to       IN VARCHAR2, -- Phone number of SMS recipient(s) colon delimited.
                                     p_sms_body IN VARCHAR2) IS
  t_http_req       utl_http.req;
  t_http_resp      utl_http.resp;
  lv_resp_line     VARCHAR2(32767);
  lv_response_text CLOB;

  v_url          VARCHAR2(200) := 'https://api.twilio.com/2010-04-01/Accounts/' ||
                                  p_user || '/SMS/Messages.xml';
  lv_post_params VARCHAR2(30000);
  lv_from        VARCHAR2(100);
  lv_to          VARCHAR2(100);
  lv_sms_body    VARCHAR2(30000);
  c_xml_response CLOB;

  lv_recipients apex_application_global.vc_arr2;
BEGIN
  c_xml_response := NULL;
  lv_from        := p_from;
  lv_sms_body    := p_sms_body;
  lv_recipients  := apex_util.string_to_table(p_to, ':');
  FOR i IN 1 .. lv_recipients.count LOOP
  
    lv_post_params := 'From=' || lv_from || '&To=' || lv_to || '&Body=' ||
                      lv_sms_body;
    lv_post_params := utl_url.escape(lv_post_params);
    v_url          := utl_url.escape(v_url);
    utl_http.set_wallet('file:' || '/vhosts/schema/api_twilio',
                        'password12');
    t_http_req := utl_http.begin_request(v_url, 'POST', 'HTTP/1.1');
    utl_http.set_authentication(t_http_req, p_user, p_pass);
    utl_http.set_header(t_http_req,
                        'Content-Type',
                        'application/x-www-form-urlencoded');
    utl_http.set_header(t_http_req,
                        'Content-Length',
                        length(lv_post_params));
    utl_http.write_text(t_http_req, lv_post_params);
    t_http_resp := utl_http.get_response(t_http_req);
    LOOP
      BEGIN
        lv_resp_line := NULL;
        utl_http.read_line(t_http_resp, lv_resp_line, TRUE);
        lv_response_text := lv_response_text || lv_resp_line;
      EXCEPTION 
      WHEN utl_http.end_of_body THEN
        utl_http.end_response(t_http_resp);
      END;
    END LOOP;
    utl_http.end_response(t_http_resp);
    dbms_output.put_line(lv_response_text);
    lv_response_text := NULL;
  END LOOP;
END send_sms;