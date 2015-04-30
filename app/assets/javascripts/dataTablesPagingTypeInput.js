$.fn.dataTableExt.oPagination.input = {
    "fnInit": function ( oSettings, nPaging, fnCallbackDraw )
    {
        var nLeftSpan = document.createElement( 'div' );
        var nRightSpan = document.createElement( 'div' );
        var nFirst = document.createElement( 'button' );
        var nPrevious = document.createElement( 'button' );
        var nNext = document.createElement( 'button' );
        var nLast = document.createElement( 'button' );
        var nInputGroup = document.createElement( 'div' );
        var nInput = document.createElement( 'input' );
        var nInputSubmit = document.createElement( 'span' );
        var nPage = document.createElement( 'span' );
        var nOf = document.createElement( 'span' );
 
        // nFirst.innerHTML = oSettings.oLanguage.oPaginate.sFirst;
        // nPrevious.innerHTML = oSettings.oLanguage.oPaginate.sPrevious;
        // nNext.innerHTML = oSettings.oLanguage.oPaginate.sNext;
        // nLast.innerHTML = oSettings.oLanguage.oPaginate.sLast;
        nFirst.innerHTML = "<<";
        nPrevious.innerHTML = "<";
        nNext.innerHTML = ">";
        nLast.innerHTML = ">>";
        nInputSubmit.innerHTML = "Go";

        nLeftSpan.className = "input-group-btn"
        nRightSpan.className = "input-group-btn"
        nFirst.className = "btn btn-default first disabled";
        nPrevious.className = "btn btn-default previous disabled";
        nNext.className= "btn btn-default next";
        nLast.className = "btn btn-default last";
        nOf.className = "paginate_of input-group-addon primary";
        nPage.className = "paginate_page input-group-addon primary";
        nInputGroup.className = "input-group";
        nInput.className = "form-control";
        nInput.setAttribute("id", "paginate_input");
        nInputSubmit.className = "input-group-addon btn btn-default";

        if ( oSettings.sTableId !== '' )
        {
            nPaging.setAttribute( 'id', oSettings.sTableId+'_paginate' );
            nFirst.setAttribute( 'id', oSettings.sTableId+'_first' );
            nPrevious.setAttribute( 'id', oSettings.sTableId+'_previous' );
            nNext.setAttribute( 'id', oSettings.sTableId+'_next' );
            nLast.setAttribute( 'id', oSettings.sTableId+'_last' );
        }
        nInput.type = "number";
        nPaging.appendChild( nInputGroup );
        nInputGroup.appendChild( nLeftSpan ); 
        nLeftSpan.appendChild( nFirst );        
        nLeftSpan.appendChild( nPrevious );
        nInputGroup.appendChild( nPage );
        nInputGroup.appendChild( nInput );
        nInputGroup.appendChild( nOf );
        nInputGroup.appendChild( nInputSubmit );
        nInputGroup.appendChild( nRightSpan );
        nRightSpan.appendChild( nNext );
        nRightSpan.appendChild( nLast );
       
        $(nFirst).click( function ()
        {
            var iCurrentPage = Math.ceil(oSettings._iDisplayStart / oSettings._iDisplayLength) + 1;
                if (iCurrentPage != 1)
                {
                oSettings.oApi._fnPageChange( oSettings, "first" );
                fnCallbackDraw( oSettings );
                }
        } );
 
        $(nPrevious).click( function()
        {
            var iCurrentPage = Math.ceil(oSettings._iDisplayStart / oSettings._iDisplayLength) + 1;
                if (iCurrentPage != 1)
                {
                oSettings.oApi._fnPageChange(oSettings, "previous");
                    fnCallbackDraw(oSettings);
            }
        } );
 
        $(nNext).click( function()
        {
            var iCurrentPage = Math.ceil(oSettings._iDisplayStart / oSettings._iDisplayLength) + 1;
            if (iCurrentPage != Math.ceil((oSettings.fnRecordsDisplay() / oSettings._iDisplayLength)))
            {
                oSettings.oApi._fnPageChange(oSettings, "next");
                fnCallbackDraw(oSettings);
            }
        } );
 
        $(nLast).click( function()
        {
            var iCurrentPage = Math.ceil(oSettings._iDisplayStart / oSettings._iDisplayLength) + 1;
                if (iCurrentPage != Math.ceil((oSettings.fnRecordsDisplay() / oSettings._iDisplayLength)))
                {
                    oSettings.oApi._fnPageChange(oSettings, "last");
                    fnCallbackDraw(oSettings);
                }
        } );

        $(nInputSubmit).click( function()
        {
            $(nInput).trigger( $.Event("keyup", { keyCode: 13, which: 13 }) );
        } );

        $(nInput).on("change input", function() {
            if ( this.value === "" || this.value.match(/[^0-9]/) ) {
                $(nInputSubmit).addClass("disabled");
            } else {
                var iCurrentPage = Math.ceil(oSettings._iDisplayStart / oSettings._iDisplayLength) + 1;
                var iPages = Math.ceil((oSettings.fnRecordsDisplay()) / oSettings._iDisplayLength);
                var iInputValue = $(nInput).val();
                if ( ( iInputValue != iCurrentPage ) && ( iInputValue <= iPages ) ) {
                    $(nInputSubmit).removeClass("disabled");
                } else {
                    $(nInputSubmit).addClass("disabled");
                }
            }
        });
 
        $(nInput).keyup( function (e) {
            // 38 = up arrow, 39 = right arrow
            // if ( e.which == 39 )
            // {
            //     this.value++;
            // }
            // // 37 = left arrow, 40 = down arrow
            // else if ( ( e.which == 37 ) && this.value > 1 )
            // {
            //     this.value--;
            // }
 
            if ( this.value === "" || this.value.match(/[^0-9]/) )
            {
                console.log("x");
                /* Nothing entered or non-numeric character */
                this.value = this.value.replace(/[^\d]/g, ''); // don't even allow anything but digits
                return;
            }
 
            if (e.which == 13) {
                var iNewStart = oSettings._iDisplayLength * (this.value - 1);
                if (iNewStart < 0)
                {
                    iNewStart = 0;
                }
                if (iNewStart > oSettings.fnRecordsDisplay())
                {
                    iNewStart = (Math.ceil((oSettings.fnRecordsDisplay() - 1) / oSettings._iDisplayLength) - 1) * oSettings._iDisplayLength;
                }

                oSettings._iDisplayStart = iNewStart;
                fnCallbackDraw( oSettings );
                $(nInput).trigger("change");
            }
        } );
 
        /* Take the brutal approach to cancelling text selection */
        $('button', nPaging).bind( 'mousedown', function () { return false; } );
        $('button', nPaging).bind( 'selectstart', function () { return false; } );

        /* Style */
        $('button', nPaging).css({"height": "34px", "width": "34px", "font-weight": "bold", "color": "#428bca", "padding": "2px"})
        $(nInputSubmit).css({"height": "34px", "width": "34px", "font-weight": "bold", "color": "#428bca", "padding": "2px"})
        $('.input-group-btn', nPaging).css({"height": "34px", "width": "66px"})
        $('input', nPaging).css({"text-align": "right", "color": "#428bca", "padding-right": "2px", "font-weight": "bold"});
        document.styleSheets[0].addRule("input[type=number]::-webkit-inner-spin-button", "margin-left: 6px;");
        nInputGroup.style.width = "400px"
        nInput.style.width = "100px"
        nInputSubmit.style.width = "34px"
        nPage.style.width = "50px"
        nOf.style.width = "75px"

        $(nInput).trigger("change");
    },
 
 
    "fnUpdate": function ( oSettings, fnCallbackDraw ) {
        if ( !oSettings.aanFeatures.p ) { return; }
        var iPages = Math.ceil((oSettings.fnRecordsDisplay()) / oSettings._iDisplayLength);
        if ( iPages == 0 ) { iPages = 1 }
        var iCurrentPage = Math.ceil(oSettings._iDisplayStart / oSettings._iDisplayLength) + 1;
        var an = oSettings.aanFeatures.p;
        /* Loop over each instance of the pager */
        for (var i = 0, iLen = an.length ; i < iLen ; i++) {
            var buttons = an[i].getElementsByTagName('button');
            var spans = an[i].getElementsByTagName('span');
            var inputs = an[i].getElementsByTagName('input');
            spans[0].innerHTML = "Page";
            spans[1].innerHTML = "of " + iPages;
            inputs[0].value = iCurrentPage;
             $('input', ".dataTables_paginate").attr({"min": 1, "max": parseInt(iPages) })
        }
    }
};