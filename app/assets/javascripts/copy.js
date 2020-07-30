// BigBlueButton open source conferencing system - http://www.bigbluebutton.org/.

// Copyright (c) 2018 BigBlueButton Inc. and by respective authors (see below).

// This program is free software; you can redistribute it and/or modify it under the
// terms of the GNU Lesser General Public License as published by the Free Software
// Foundation; either version 3.0 of the License, or (at your option) any later
// version.

// BigBlueButton is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
// PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.

// You should have received a copy of the GNU Lesser General Public License along
// with BigBlueButton; if not, see <http://www.gnu.org/licenses/>.

$(document).on('turbolinks:load', function(){

    $('.click-to-copy').on('click', function() {
        let self = $(this);
        self.select();
        // $(this).setSelectionRange(0, 99999); /* For mobile devices */

        copied_txt = 'Copied!';

        document.execCommand("copy");
        self
            .data('placement', 'top')
            .attr('title', copied_txt)
            .tooltip('show');

        setTimeout(function() {
            self.tooltip('destroy');
        }, 2000);
    });

});