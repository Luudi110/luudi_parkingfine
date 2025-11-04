Locales['en'] = {
    -- General messages
    ['no_access'] = 'You do not have access to this system',
    ['not_authorized'] = 'You are not authorized to issue fines',
    ['invalid_amount'] = 'Invalid fine amount',
    ['missing_reason'] = 'You must specify a reason for the fine',
    ['player_not_found'] = 'Target player not found',
    ['no_player_nearby'] = 'There is no player in a vehicle nearby',
    ['database_error'] = 'An error occurred communicating with the database',
    
    -- Fine messages
    ['fine_issued'] = 'Parking fine issued',
    ['fine_issued_desc'] = 'You have issued a parking fine of $%s to %s',
    ['fine_received'] = 'Parking fine received',
    ['fine_received_desc'] = 'You have received a parking fine of $%s\nReason: %s',
    ['fine_paid'] = 'Fine paid',
    ['fine_paid_desc'] = 'You have paid fine #%s of $%s',
    ['fine_marked_paid'] = 'Fine #%s has been marked as paid',
    ['fine_already_paid'] = 'This fine has already been paid',
    ['fine_not_found'] = 'Fine not found',
    
    -- Money messages
    ['insufficient_funds'] = 'Insufficient funds',
    ['insufficient_funds_desc'] = 'You need $%s more to pay this fine',
    ['payment_processed'] = 'Payment processed',
    ['payment_processed_desc'] = '$%s has been deducted from your %s',
    ['not_enough_money_warning'] = 'The player did not have enough money. The fine has been issued as unpaid.',
    ['auto_deducted'] = 'The amount has been automatically deducted from your bank account',
    ['manual_payment'] = 'The fine must be paid manually',
    
    -- Menu titles
    ['main_menu'] = 'Parking Fine System',
    ['issue_fine'] = 'Issue Parking Fine',
    ['issue_fine_desc'] = 'Give a parking fine to a person in a vehicle',
    ['view_fines'] = 'View Issued Fines',
    ['view_fines_desc'] = 'Display a list of all issued fines',
    ['fine_details'] = 'Fine #%s',
    ['my_fines'] = 'My Fines',
    ['no_fines'] = 'No fines',
    ['no_fines_desc'] = 'There are no registered fines',
    
    -- Input fields
    ['fine_amount'] = 'Fine Amount',
    ['fine_amount_desc'] = 'Enter the fine amount (between %s and %s)',
    ['fine_reason'] = 'Reason',
    ['fine_reason_desc'] = 'Enter the reason for the fine',
    ['auto_deduct'] = 'Automatically deduct from bank account',
    ['auto_deduct_desc'] = 'If enabled, the amount will be automatically deducted from the player\'s bank account',
    
    -- Status messages
    ['paid'] = 'Paid',
    ['unpaid'] = 'Unpaid',
    ['mark_as_paid'] = 'Mark as Paid',
    ['mark_as_paid_desc'] = 'Mark this fine as paid',
    ['back'] = 'Back',
    ['back_desc'] = 'Go back to previous menu',
    
    -- Command messages
    ['invalid_command'] = 'Invalid command',
    ['invalid_command_usage'] = 'Usage: %s',
    ['no_personal_fines'] = 'You have no registered parking fines',
    ['your_fines'] = 'Your parking fines:',
}
