-- This PL/SQL script defines a stored procedure `send_sms` that sends SMS messages using the Twilio API.
-- It fulfills the business requirement of enabling automated SMS notifications by interacting with the Twilio service.
-- The procedure takes user credentials, a sender phone number, recipient phone numbers, and the message body as input.

CREATE OR REPLACE PROCEDURE send_sms(p_user     IN VARCHAR2, -- Twilio user name
                                     p_pass     IN VARCHAR2, -- Twilio password
                                     p_from     IN VARCHAR2, -- Twilio From phone number
                                     p_to       IN VARCHAR2, -- Phone number of SMS recipient(s) colon delimited.
                                     p_sms_body IN VARCHAR2) IS
  t_http_req       utl_http.req;  -- HTTP request object
  t_http_resp      utl_http.resp; -- HTTP response object
  lv_resp_line     VARCHAR2(32767); -- Line of response text
  lv_response_text CLOB;           -- Full response text

  -- Construct the URL for the Twilio API endpoint
  v_url          VARCHAR2(200) := 'https://api.twilio.com/2010-04-01/Accounts/' ||
                                  p_user || '/SMS/Messages.xml';
  lv_post_params VARCHAR2(30000); -- Parameters for POST request
  lv_from        VARCHAR2(100);   -- Sender phone number
  lv_to          VARCHAR2(100);   -- Recipient phone number
  lv_sms_body    VARCHAR2(30000); -- SMS message body
  c_xml_response CLOB;            -- XML response placeholder

  lv_recipients apex_application_global.vc_arr2; -- Array to hold multiple recipients
BEGIN
  c_xml_response := NULL;
  lv_from        := p_from;
  lv_sms_body    := p_sms_body;
  -- Convert colon-delimited recipient string into an array
  lv_recipients  := apex_util.string_to_table(p_to, ':');
  FOR i IN 1 .. lv_recipients.count LOOP
    -- Prepare POST parameters for each recipient
    lv_post_params := 'From=' || lv_from || '&To=' || lv_to || '&Body=' ||
                      lv_sms_body;
    lv_post_params := utl_url.escape(lv_post_params); -- Escape parameters for URL
    v_url          := utl_url.escape(v_url);          -- Escape URL
    -- Set up the wallet for secure HTTP communication
    utl_http.set_wallet('file:' || '/vhosts/schema/api_twilio',
                        'password12');
    -- Begin HTTP POST request
    t_http_req := utl_http.begin_request(v_url, 'POST', 'HTTP/1.1');
    -- Set basic authentication for Twilio API
    utl_http.set_authentication(t_http_req, p_user, p_pass);
    -- Set headers for the HTTP request
    utl_http.set_header(t_http_req,
                        'Content-Type',
                        'application/x-www-form-urlencoded');
    utl_http.set_header(t_http_req,
                        'Content-Length',
                        length(lv_post_params));
    -- Write the POST parameters to the request
    utl_http.write_text(t_http_req, lv_post_params);
    -- Get the response from the HTTP request
    t_http_resp := utl_http.get_response(t_http_req);
    LOOP
      BEGIN
        lv_resp_line := NULL;
        -- Read each line of the response
        utl_http.read_line(t_http_resp, lv_resp_line, TRUE);
        lv_response_text := lv_response_text || lv_resp_line; -- Accumulate response text
      EXCEPTION 
      WHEN utl_http.end_of_body THEN
        utl_http.end_response(t_http_resp); -- End response when body is fully read
      END;
    END LOOP;
    utl_http.end_response(t_http_resp); -- Ensure the response is properly closed
    dbms_output.put_line(lv_response_text); -- Output the response for debugging/logging
    lv_response_text := NULL; -- Reset response text for the next iteration
  END LOOP;
END send_sms;