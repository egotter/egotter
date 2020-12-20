require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'google/apis/drive_v3'
require 'google/apis/sheets_v4'

require 'google_drive'

class SheetsClient

  OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'

  # https://developers.google.com/identity/protocols/oauth2/scopes
  SCOPE = [
      Google::Apis::DriveV3::AUTH_DRIVE,
      Google::Apis::SheetsV4::AUTH_SPREADSHEETS
  ]

  def initialize
    @drive = Google::Apis::DriveV3::DriveService.new
    @drive.authorization = build_credentials

    @sheets = Google::Apis::SheetsV4::SheetsService.new
    @sheets.authorization = build_credentials

    session = GoogleDrive::Session.from_config('.google/config_sheets.json')
  end

  def files
    @drive.list_files(page_size: 10, spaces: 'drive', fields: 'nextPageToken, files(id, name)').files
  end

  def spreadsheet(id)
    @sheets.get_spreadsheet(id)
  end

  def worksheets(id)
    spreadsheet(id).sheets
  end

  def spreadsheet_values(spreadsheet_id, worksheet_title, range = 'A1:Z1')
    @sheets.get_spreadsheet_values(
        spreadsheet_id,
        "'#{worksheet_title}'!#{range}",
    )
  end

  def update_spreadsheet(spreadsheet_id, worksheet_title, range = 'A1:Z1', values)
    value_range = Google::Apis::SheetsV4::ValueRange.new
    value_range.major_dimension = 'ROWS' # or COLUMNS
    value_range.values = [values]
    @sheets.update_spreadsheet_value(
        spreadsheet_id,
        "'#{worksheet_title}'!#{range}",
        value_range,
        value_input_option: 'RAW', # or USER_ENTERED
    )
  end

  def build_credentials
    client_id = Google::Auth::ClientId.from_file('.google/client_secret_sheets.json')
    token_store = Google::Auth::Stores::FileTokenStore.new(file: '.google/credentials_sheets.yaml')
    authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)

    if (credentials = authorizer.get_credentials('default')).nil?
      url = authorizer.get_authorization_url(base_url: OOB_URI)
      puts "Open #{url} in your browser and enter the resulting code:"
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(user_id: 'default', code: code, base_url: OOB_URI)
    end

    credentials
  end
end
