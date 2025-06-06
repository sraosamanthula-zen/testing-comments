-- File Overview:
-- This PL/SQL procedure, `send_sms`, is designed to send SMS messages using the Twilio API. 
-- It takes in Twilio credentials, a sender phone number, recipient phone numbers, and the message body as parameters.
-- The procedure loops through the recipients, sending the message to each one individually.

CREATE OR REPLACE PROCEDURE send_sms(
  p_user     IN VARCHAR2, -- Twilio user name
  p_pass     IN VARCHAR2, -- Twilio password
  p_from     IN VARCHAR2, -- Twilio From phone number
  p_to       IN VARCHAR2, -- Phone number of SMS recipient(s) colon delimited.
  p_sms_body IN VARCHAR2  -- SMS message body
) IS
  t_http_req       utl_http.req;  -- HTTP request object
  t_http_resp      utl_http.resp; -- HTTP response object
  lv_resp_line     VARCHAR2(32767); -- Line of response text
  lv_response_text CLOB;           -- Full response text

  v_url          VARCHAR2(200) := 'https://api.twilio.com/2010-04-01/Accounts/' ||
                                  p_user || '/SMS/Messages.xml'; -- Twilio API URL
  lv_post_params VARCHAR2(30000); -- POST parameters for the HTTP request
  lv_from        VARCHAR2(100);   -- Sender phone number
  lv_to          VARCHAR2(100);   -- Recipient phone number
  lv_sms_body    VARCHAR2(30000); -- SMS message body
  c_xml_response CLOB;            -- XML response from Twilio

  lv_recipients apex_application_global.vc_arr2; -- Array of recipient phone numbers
BEGIN
  c_xml_response := NULL;  -- Initialize XML response
  lv_from        := p_from;  -- Set sender phone number
  lv_sms_body    := p_sms_body;  -- Set SMS message body
  lv_recipients  := apex_util.string_to_table(p_to, ':'); -- Split recipients by colon

  -- Loop through each recipient and send an SMS
  FOR i IN 1 .. lv_recipients.count LOOP
    lv_to := lv_recipients(i); -- Current recipient phone number

    -- Prepare POST parameters
    lv_post_params := 'From=' || lv_from || '&To=' || lv_to || '&Body=' ||
                      lv_sms_body;  -- Construct POST parameters
    lv_post_params := utl_url.escape(lv_post_params); -- Escape URL parameters
    v_url          := utl_url.escape(v_url);          -- Escape URL

    -- Set up HTTP request
    utl_http.set_wallet('file:' || '/vhosts/schema/api_twilio', 'password12');  -- Set wallet for secure connection
    t_http_req := utl_http.begin_request(v_url, 'POST', 'HTTP/1.1');  -- Begin HTTP request
    utl_http.set_authentication(t_http_req, p_user, p_pass); -- Set authentication
    utl_http.set_header(t_http_req, 'Content-Type', 'application/x-www-form-urlencoded');  -- Set content type header
    utl_http.set_header(t_http_req, 'Content-Length', length(lv_post_params));  -- Set content length header
    utl_http.write_text(t_http_req, lv_post_params); -- Write POST data

    -- Get HTTP response
    t_http_resp := utl_http.get_response(t_http_req);  -- Get response from HTTP request
    LOOP
      BEGIN
        lv_resp_line := NULL;  -- Initialize response line
        utl_http.read_line(t_http_resp, lv_resp_line, TRUE); -- Read response line
        lv_response_text := lv_response_text || lv_resp_line; -- Append to response text
      EXCEPTION 
      WHEN utl_http.end_of_body THEN
        utl_http.end_response(t_http_resp); -- End response when body is fully read
      END;
    END LOOP;
    utl_http.end_response(t_http_resp); -- Ensure response is ended

    dbms_output.put_line(lv_response_text); -- Output the response
    lv_response_text := NULL; -- Reset response text for next iteration
  END LOOP;
END send_sms;