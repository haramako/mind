package main

import (
	"flag"
	"fmt"
	"image"
	"image/color"
	"image/draw"
	"image/png"
	"os"
	"path/filepath"
	"sync"
)

var tempDir string

var optBatch = flag.Bool("b", false, "Batch mode")
var optPostfix = flag.String("postfix", ".tsp", "Run as batch mode. (Default '.tsp')")
var optOutDir = flag.String("outdir", "", "Output directory")
var optSplit = flag.Bool("split", false, "Split channel")
var optJobs = flag.Int("j", 4, "Parallel job number, enable only batch mode.")

func check(err error) {
	if err != nil {
		panic(err)
	}
}

var count = 0

// メインエントリ
func main() {
	flag.Usage = func() {
		fmt.Println("png2tsp: texture converter for dynamic atlas")
		flag.PrintDefaults()
	}
	flag.Parse()

	if *optBatch {
		// バッチモード
		if flag.NArg() <= 0 {
			flag.PrintDefaults()
			os.Exit(1)
		}

		doBatch(flag.Args())

	} else {
		// １ファイル変換モード

		if flag.NArg() != 2 {
			flag.PrintDefaults()
			os.Exit(1)
		}

		args := flag.Args()
		convert(args[0], args[1])
	}
}

// バッチモードで起動する
func doBatch(files []string) {
	w := NewWorker(*optJobs, func(in interface{}) {
		infile := in.(string)
		ext := filepath.Ext(infile)
		basename := filepath.Base(infile)
		basename = basename[0 : len(basename)-len(ext)]
		dir := filepath.Dir(infile)
		if *optOutDir != "" {
			dir = *optOutDir
		}
		outfile := filepath.Join(dir, basename+*optPostfix)
		fmt.Printf("converting %v ...\n", outfile)

		convert(infile, outfile)
	})

	for _, f := range files {
		w.AddTask(f)
	}

	w.Close()
}

// ファイルをTSPにコンバートする
func convert(in, out string) {

	r, err := os.Open(in)
	check(err)

	srcImg, err := png.Decode(r)
	check(err)

	nrgbaImg := image.NewNRGBA(srcImg.Bounds())
	draw.Draw(nrgbaImg, srcImg.Bounds(), srcImg, image.Point{0, 0}, draw.Src)

	img := NRGBImageToHSV(nrgbaImg)

	if *optSplit {
		// チャンネルスプリットする
		imgs := SplitChannel(img)
		channel := "CHSV"
		for i := 0; i < 4; i++ {
			ext := filepath.Ext(out)
			basename := filepath.Base(out)
			basename = basename[0 : len(basename)-len(ext)]
			w, err := os.OpenFile(basename+"_"+string(channel[i])+ext, os.O_CREATE|os.O_WRONLY, 0666)
			check(err)

			err = png.Encode(w, imgs[i])
			check(err)
		}

	} /* else {*/
	// チャンネルスプリットしない

	w, err := os.OpenFile(out, os.O_CREATE|os.O_WRONLY, 0666)
	check(err)

	err = png.Encode(w, img)
	check(err)
	//}

}

func RGBToHSV(c color.NRGBA) color.NRGBA {
	r := int(c.R)
	g := int(c.G)
	b := int(c.B)
	a := int(c.A)

	max := imax(imax(r, g), b)
	min := imin(imin(r, g), b)

	diff := max - min
	if diff <= 0 {
		diff = 1
	}

	var h int
	if min == b {
		h = (60*(g-r)/diff + 60) * 256 / 360
	} else if min == r {
		h = (60*(b-g)/diff + 180) * 256 / 360
	} else {
		h = (60*(r-b)/diff + 300) * 256 / 360
	}
	h = h % 256

	var s int
	if max > 0 {
		s = diff * 255 / max
	} else {
		s = 0
	}

	return color.NRGBA{uint8(h), uint8(s), uint8(max), uint8(a)}
}
func HSVToRGB(col color.NRGBA) color.NRGBA {
	h := int(col.R)
	s := int(col.G)
	v := int(col.B)
	a := int(col.A)

	var r, g, b int

	h_ := h * 6 / 255
	h_mod2 := (h * 6 % 510)
	c := v * s / 255
	// x := int(float64(c) * (1 - math.Abs(math.Mod(h_, 2)-1)))
	x := c * (255 - abs(h_mod2-255)) / 255
	vc := v - c
	switch int(h_) {
	case 0:
		r, g, b = vc+c, vc+x, vc
		break
	case 1:
		r, g, b = vc+x, vc+c, vc
		break
	case 2:
		r, g, b = vc, vc+c, vc+x
		break
	case 3:
		r, g, b = vc, vc+x, vc+c
		break
	case 4:
		r, g, b = vc+x, vc, vc+c
		break
	case 5:
		r, g, b = vc+c, vc, vc+x
		break
	}

	r = clamp(r)
	g = clamp(g)
	b = clamp(b)

	return color.NRGBA{uint8(r), uint8(g), uint8(b), uint8(a)}
}

// カラー成分のみの画像を作成する
// RGBA <= RGB1
func NRGBImageToHSV(src *image.NRGBA) *image.NRGBA {
	size := src.Bounds().Size()
	img := image.NewNRGBA(image.Rect(0, 0, size.X, size.Y))
	for y := 0; y < size.Y; y++ {
		for x := 0; x < size.X; x++ {
			var c = src.NRGBAAt(x, y)
			var hsv = RGBToHSV(c)
			img.SetNRGBA(x, y, hsv)
		}
	}
	return img
}

// カラー成分のみの画像を作成する
// RGBA <= RGB1
func SplitChannel(src *image.NRGBA) []*image.NRGBA {
	var imgs [4]*image.NRGBA
	for i := 0; i < 4; i++ {
		imgs[i] = image.NewNRGBA(src.Bounds())
	}
	size := src.Bounds().Size()
	for y := 0; y < size.Y; y++ {
		for x := 0; x < size.X; x++ {
			var c = src.NRGBAAt(x, y)
			//imgs[0].SetNRGBA(x, y, HSVToRGB(c))
			imgs[0].SetNRGBA(x, y, HSVToRGB(color.NRGBA{c.R, 255, 255, c.A}))
			imgs[1].SetNRGBA(x, y, color.NRGBA{c.R, 0, 0, c.A})
			imgs[2].SetNRGBA(x, y, color.NRGBA{0, c.G, 0, c.A})
			imgs[3].SetNRGBA(x, y, color.NRGBA{0, 0, c.B, c.A})
		}
	}
	return imgs[:]
}

//============================================

// 並列で処理を行うWorker
type Worker struct {
	wg sync.WaitGroup
	ch chan interface{}
}

func NewWorker(num int, f func(interface{})) *Worker {
	t := &Worker{
		wg: sync.WaitGroup{},
		ch: make(chan interface{}),
	}

	for i := 0; i < num; i++ {
		t.wg.Add(1)
		go func() {
			defer func() {
				t.wg.Done()
			}()
			for arg := range t.ch {
				f(arg)
			}
		}()
	}
	return t
}

func (t *Worker) AddTask(task interface{}) {
	t.ch <- task
}

func (t *Worker) Close() {
	close(t.ch)
	t.wg.Wait()
}

func abs(a int) int {
	if a < 0 {
		return -a
	} else {
		return a
	}
}

func clamp(a int) int {
	if a > 256 {
		return 255
	} else if a < 0 {
		return 0
	} else {
		return a
	}
}

func imax(a, b int) int {
	if a < b {
		return b
	} else {
		return a
	}
}

func imin(a, b int) int {
	if a < b {
		return a
	} else {
		return b
	}
}
