-- This SQL file contains a stored procedure for sending SMS messages using the Twilio API.
-- The procedure 'send_sms' is designed to fulfill the business requirement of sending text messages
-- to multiple recipients by utilizing Twilio's SMS service. It accepts parameters for authentication,
-- sender and recipient phone numbers, and the message body, then constructs and sends HTTP POST requests
-- to Twilio's API endpoint.

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
                                  p_user || '/SMS/Messages.xml'; -- URL for Twilio API endpoint
  lv_post_params VARCHAR2(30000); -- POST parameters for the HTTP request
  lv_from        VARCHAR2(100); -- Sender phone number
  lv_to          VARCHAR2(100); -- Recipient phone number
  lv_sms_body    VARCHAR2(30000); -- SMS message body
  c_xml_response CLOB; -- Placeholder for XML response

  lv_recipients apex_application_global.vc_arr2; -- Array to hold multiple recipients
BEGIN
  c_xml_response := NULL; -- Initialize XML response
  lv_from        := p_from; -- Assign sender phone number
  lv_sms_body    := p_sms_body; -- Assign SMS message body
  lv_recipients  := apex_util.string_to_table(p_to, ':'); -- Split recipient phone numbers into an array

  FOR i IN 1 .. lv_recipients.count LOOP -- Loop through each recipient
    lv_to := lv_recipients(i); -- Assign current recipient phone number

    -- Construct POST parameters for the HTTP request
    lv_post_params := 'From=' || lv_from || '&To=' || lv_to || '&Body=' ||
                      lv_sms_body;
    lv_post_params := utl_url.escape(lv_post_params); -- Escape POST parameters
    v_url          := utl_url.escape(v_url); -- Escape URL

    -- Set up the wallet for SSL communication
    utl_http.set_wallet('file:' || '/vhosts/schema/api_twilio',
                        'password12'); -- FIXME: Ensure the wallet path and password are correct

    -- Begin HTTP request
    t_http_req := utl_http.begin_request(v_url, 'POST', 'HTTP/1.1');

    -- Set authentication for the HTTP request
    utl_http.set_authentication(t_http_req, p_user, p_pass);

    -- Set headers for the HTTP request
    utl_http.set_header(t_http_req,
                        'Content-Type',
                        'application/x-www-form-urlencoded');
    utl_http.set_header(t_http_req,
                        'Content-Length',
                        length(lv_post_params));

    -- Write POST parameters to the HTTP request
    utl_http.write_text(t_http_req, lv_post_params);

    -- Get HTTP response
    t_http_resp := utl_http.get_response(t_http_req);

    -- Read the response line by line
    LOOP
      BEGIN
        lv_resp_line := NULL; -- Reset response line variable
        utl_http.read_line(t_http_resp, lv_resp_line, TRUE); -- Read a line from the response
        lv_response_text := lv_response_text || lv_resp_line; -- Append line to response text
      EXCEPTION 
      WHEN utl_http.end_of_body THEN -- Handle end of response body
        utl_http.end_response(t_http_resp); -- End the HTTP response
      END;
    END LOOP;

    -- End the HTTP response
    utl_http.end_response(t_http_resp);

    -- Output the accumulated response text
    dbms_output.put_line(lv_response_text);

    -- Reset response text for the next recipient
    lv_response_text := NULL;
  END LOOP;
END send_sms;