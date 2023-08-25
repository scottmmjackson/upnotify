use std::thread::sleep;
use std::time::Duration;

use clap::{arg, ArgAction, Command, crate_authors, crate_description, crate_name, crate_version};
use reqwest::blocking::Client;
use reqwest::StatusCode;

enum Result {
    StatusCode(StatusCode),
    ConnectError(reqwest::Error),
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
        match client.get(url).send() {
            Ok(result) => {
                let status_code = result.status();
                match previous_status_option {
                    Result::StatusCode(previous_status)
                    if status_code.as_u16() != previous_status.as_u16() => {
                        println!("Status changed to {:?}", status_code)
                    }
                    Result::None => {
                        println!("Status changed to {:?}", status_code)
                    }
                    _ => {}
                }
                previous_status_option = Result::StatusCode(status_code);
            }
            Err(error) => {
                match previous_status_option {
                    Result::ConnectError(_error) if error.is_connect() => {}
                    _ => {
                        if error.is_connect() {
                            println!("Status changed to connection failed");
                        } else {
                            println!("Error: {}", error);
                        }
                    }
                }
                previous_status_option = if error.is_connect() { Result::ConnectError(error) } else { Result::OtherError(error) }
            }
        }
        sleep(Duration::from_secs(5));
    }
}
