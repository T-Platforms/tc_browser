// The Computer Language Shootout
// http://shootout.alioth.debian.org/
// contributed by Isaac Gouy

function ack(m,n){
   if (m==0) { return n+1; }
   if (n==0) { return ack(m-1,1); }
   return ack(m-1, ack(m,n-1) );
}

function fib(n) {
    if (n < 2){ return 1; }
    return fib(n-2) + fib(n-1);
}

function fibnonrec (n){
	if(n <= 1){ return 1; }
 	var fibo = 1;
 	var fiboPrev = 1;
 	for(var i = 2; i < n; ++i){
 	 var temp = fibo;
  	fibo += fiboPrev;
  	fiboPrev = temp;
  	}
 return fibo;
}

function floop (n){
	var tmp = 1;
	for(var i = 1; i < n; ++i){
		tmp++;
	}
	return n;
} 

function idle (n){
	return n+1;
}

function fcall (n){
	var tmp;
	for(var i = 1; i < n; ++i){
	tmp = idle(i);	
	}
	return n;
}

function frec(n) {
	var tmp = n + 1;    
	if (n < 2){ return 1; }
    return frec(n-1);
}

function tak(x,y,z) {
	if (y >= x) return z;
	return tak(tak(x-1,y,z), tak(y-1,z,x), tak(z-1,x,y));
}

startTest("sunspider-controlflow-recursive");

	test("Ack", function(){
		for ( var i = 3; i <= 5; i++ )
			ack(3,i);
	});
	
	test("Fib", function(){
		for ( var i = 3; i <= 5; i++ )
			fib(17.0+i);
	});
	
	test("Tak", function(){
		for ( var i = 3; i <= 5; i++ )
			tak(3*i+3,2*i+2,i+1);
	});
	
	test("Simple loop", function(){
		for ( var i = 1; i <= 1000; i++ )
			floop(i);
	});

	test("Idle call", function(){
		for ( var i = 1; i <= 1000; i++ )
			fcall(i);
	});
	
	test("Simple recursion 4", function(){
			frec(4);
	});

	test("Simple recursion 8", function(){
			frec(8);
	});

	test("Simple recursion 16", function(){
			frec(16);
	});

	test("Simple recursion 32", function(){
			frec(32);
	});

	test("Simple recursion 64", function(){
			frec(64);
	});

	test("Simple recursion 128", function(){
			frec(128);
	});

	test("Simple recursion 256", function(){
			frec(256);
	});

	test("Simple recursion 512", function(){
			frec(512);
	});

	test("Simple recursion 1024", function(){
			frec(1024);
	});

	test("Simple recursion 2048", function(){
			frec(2048);
	});

	test("Simple recursion 4096", function(){
			frec(4096);
	});

	test("Simple recursion 8192", function(){
			frec(8192);
	});

	test("Simple recursion 16384", function(){
			frec(16384);
	});

/*
// Can cause stack overflow!	
	test("Simple recursion 32768", function(){
			frec(32768);
	});
*/

endTest();
