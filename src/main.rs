use std::thread::sleep;
use std::time::Duration;

use clap::{arg, ArgAction, Command, crate_authors, crate_description, crate_name, crate_version};
use reqwest::blocking::Client;
use reqwest::StatusCode;

enum Result {
    StatusCode(StatusCode),
    ConnectError(reqwest::Error),
    TimeoutError(reqwest::Error),
    RequestError(reqwest::Error),
    OtherError(reqwest::Error),
    None,
}

fn main() {
    let cli = Command::new(crate_name!())
        .version(crate_version!())
        .author(crate_authors!())
        .about(crate_description!())
        .arg(
            arg!(--url <VALUE>).required(true).action(ArgAction::Set)
        )
        .get_matches();

    let url = cli.get_one::<String>("url").expect("required");
    let client = Client::builder()
        .danger_accept_invalid_certs(true)
        .build().unwrap_or_else(|_result| panic!("Unable to create client!"));
    let mut previous_status_option: Result = Result::None;

    loop {
        let response = dbg!(client.get(url).send());
        previous_status_option = request_loop(response, previous_status_option);
        sleep(Duration::from_secs(5));
    }
}

fn request_loop(response: reqwest::Result<reqwest::blocking::Response>,
                previous_status_option: Result) -> Result {
    return match response {
        Ok(result) => {
            let status_code = result.status();
            match previous_status_option {
                Result::StatusCode(previous_status)
                if status_code.as_u16() != previous_status.as_u16() => {
                    println!("Status changed to {:?}", status_code)
                }
                Result::None | Result::TimeoutError(_) | Result::ConnectError(_) |
                Result::RequestError(_) | Result::OtherError(_) => {
                    println!("Status changed to {:?}", status_code)
                }
                _ => {}
            }
            Result::StatusCode(status_code)
        }
        Err(error) => {
            match previous_status_option {
                Result::ConnectError(_error) if error.is_connect() => {}
                Result::TimeoutError(_error) if error.is_timeout() => {}
                Result::RequestError(_error) if error.is_request() => {}
                _ => {
                    if error.is_connect() {
                        println!("Status changed to connection failed");
                    } else if error.is_timeout() {
                        println!("Status changed to timed out");
                    } else if error.is_request() {
                        println!("Status changed to request error");
                    } else {
                        println!("Error: {}", error);
                    }
                }
            }
            if error.is_connect() {
                Result::ConnectError(error)
            } else if error.is_timeout() {
                Result::TimeoutError(error)
            } else if error.is_request() {
                Result::RequestError(error)
            } else {
                Result::OtherError(error)
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use reqwest::blocking::Response;
    use http::{Response as HttpResponse, StatusCode};
    use crate::request_loop;
    use crate::Result;

    #[test]
    fn test_request_loop() {
        // Unfortunately, reqwest doesn't really let us mock results :(
        let result200 = reqwest::Result::Ok(Response::from(
            HttpResponse::builder().status(StatusCode::OK).body("").unwrap()
        ));
        let result = request_loop(result200,
                         Result::StatusCode(StatusCode::NOT_FOUND));
        match result {
            Result::StatusCode(StatusCode::OK) => {  /* ok */ },
                _ => { panic!("Unexpected status code!", )}
        }
    }
}
