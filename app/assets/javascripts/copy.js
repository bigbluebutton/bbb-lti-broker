$(document).on('turbolinks:load', function(){

    $('.click-to-copy').on('click', function() {
        let self = $(this);
        self.select();
        // $(this).setSelectionRange(0, 99999); /* For mobile devices */

        document.execCommand("copy");
        self
            .data('placement', 'top')
            .attr('title', 'Copied!')
            .tooltip('show');

        setTimeout(function() {
            self.tooltip('destroy');
        }, 2000);
    });

});