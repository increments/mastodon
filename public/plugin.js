//katex math rendering.
function katexRender(){
    status_contents=document.querySelectorAll("div.status__content p:not(.math)");
    for (var i=0;i<status_contents.length;i++) {
        renderMathInElement(status_contents[i]);
	    status_contents[i].setAttribute("class","math");
    }
}

// run par 160ms.
var render_id=window.setInterval((function(){
    katexRender();
}),160);
