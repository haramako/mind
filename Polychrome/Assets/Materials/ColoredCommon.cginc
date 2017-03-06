
// RGBをHSVに変換する
// 帰り値の HSVA は RGBA に対応する
fixed4 RGBToHSV(fixed4 c){
	fixed max_ = max(max(c.r, c.g), c.b);
	fixed min_ = min(min(c.r, c.g), c.b);
	fixed diff = max_ - min_;
	fixed4 hsv;
	if( min_ == c.b ){
		hsv.r = 60/360.0 * (c.g - c.r) / diff + 60/360.0;
	}else if( min_ == c.r ){
		hsv.r = 60/360.0 * (c.b - c.g) / diff + 180/360.0;
	}else{
	 	hsv.r = 60/360.0 * (c.r - c.b) / diff + 300/360.0;
	}
	hsv.g = diff;
	hsv.b = max_;
	hsv.a = c.a;
	return hsv;
}

fixed4 HSVToRGB(fixed4 hsv){
	float h_ = hsv.r * 6.0;
	int h_int = floor(h_);
	fixed4 r;
	fixed c = hsv.g;
	fixed x = c * (1 - abs(h_ % 2 - 1));
	fixed vc = hsv.b - c;
	if( h_int == 0 ){
		x = c * h_;
		return fixed4(vc + c, vc + x, vc    , hsv.a);
	} else if( h_int == 1 ){
		x = c * (2 - h_);
		return fixed4(vc + x, vc + c, vc    , hsv.a);
	} else if( h_int == 2 ){
		x = c * (-2 + h_);
		return fixed4(vc    , vc + c, vc + x, hsv.a);
	} else if( h_int == 3 ){
		x = c * (4 - h_);
		return fixed4(vc    , vc + x, vc + c, hsv.a);
	} else if( h_int == 4 ){
		x = c * (-4 + h_);
		return fixed4(vc + x, vc    , vc + c, hsv.a);
	} else if( h_int == 5 ){
		x = c * (6 - h_);
		return fixed4(vc + c, vc    , vc + x, hsv.a);
	} else {
		return 0;
	}
}
