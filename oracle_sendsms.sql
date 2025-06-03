-- This SQL file defines a stored procedure `send_sms` that sends SMS messages using the Twilio API.
-- The procedure takes parameters for authentication, sender and recipient phone numbers, and the SMS body.
-- It fulfills the business requirement of automating SMS notifications to multiple recipients.

CREATE OR REPLACE PROCEDURE send_sms(p_user     IN VARCHAR2, -- Twilio user name
                                     p_pass     IN VARCHAR2, -- Twilio password
                                     p_from     IN VARCHAR2, -- Twilio From phone number
                                     p_to       IN VARCHAR2, -- Phone number of SMS recipient(s) colon delimited.
                                     p_sms_body IN VARCHAR2) IS
  t_http_req       utl_http.req; -- HTTP request object
  t_http_resp      utl_http.resp; -- HTTP response object
  lv_resp_line     VARCHAR2(32767); -- Variable to store a line of the HTTP response
  lv_response_text CLOB; -- Variable to accumulate the full HTTP response

  v_url          VARCHAR2(200) := 'https://api.twilio.com/2010-04-01/Accounts/' ||
                                  p_user || '/SMS/Messages.xml'; -- Twilio API URL for sending SMS
  lv_post_params VARCHAR2(30000); -- Parameters for the HTTP POST request
  lv_from        VARCHAR2(100); -- Sender phone number
  lv_to          VARCHAR2(100); -- Recipient phone number
  lv_sms_body    VARCHAR2(30000); -- SMS message body
  c_xml_response CLOB; -- Placeholder for XML response (currently unused)

  lv_recipients apex_application_global.vc_arr2; -- Array to hold multiple recipients
BEGIN
  c_xml_response := NULL; -- Initialize XML response as NULL
  lv_from        := p_from; -- Assign sender phone number
  lv_sms_body    := p_sms_body; -- Assign SMS message body
  lv_recipients  := apex_util.string_to_table(p_to, ':'); -- Split recipient phone numbers into an array using colon delimiter
  FOR i IN 1 .. lv_recipients.count LOOP -- Loop through each recipient
  
    lv_post_params := 'From=' || lv_from || '&To=' || lv_to || '&Body=' ||
                      lv_sms_body; -- Construct POST parameters for the request
    lv_post_params := utl_url.escape(lv_post_params); -- Escape special characters in POST parameters
    v_url          := utl_url.escape(v_url); -- Escape special characters in URL
    utl_http.set_wallet('file:' || '/vhosts/schema/api_twilio',
                        'password12'); -- Set wallet for secure HTTP communication
    t_http_req := utl_http.begin_request(v_url, 'POST', 'HTTP/1.1'); -- Begin HTTP POST request
    utl_http.set_authentication(t_http_req, p_user, p_pass); -- Set HTTP basic authentication
    utl_http.set_header(t_http_req,
                        'Content-Type',
                        'application/x-www-form-urlencoded'); -- Set content type for POST request
    utl_http.set_header(t_http_req,
                        'Content-Length',
                        length(lv_post_params)); -- Set content length for POST request
    utl_http.write_text(t_http_req, lv_post_params); -- Write POST parameters to request
    t_http_resp := utl_http.get_response(t_http_req); -- Get HTTP response
    LOOP
      BEGIN
        lv_resp_line := NULL; -- Initialize response line as NULL
        utl_http.read_line(t_http_resp, lv_resp_line, TRUE); -- Read a line from the HTTP response
        lv_response_text := lv_response_text || lv_resp_line; -- Accumulate response lines into full response text
      EXCEPTION 
      WHEN utl_http.end_of_body THEN
        utl_http.end_response(t_http_resp); -- End HTTP response when the end of the body is reached
      END;
    END LOOP;
    utl_http.end_response(t_http_resp); -- Ensure response is properly ended
    dbms_output.put_line(lv_response_text); -- Output the accumulated response text
    lv_response_text := NULL; -- Reset response text for next iteration
  END LOOP;
END send_sms;