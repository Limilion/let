import { Controller, Post, UseInterceptors, UploadedFile } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname, join } from 'path';
import { mkdirSync } from 'fs';

@Controller()
export class AppController {
  @Post('upload_media')
  @UseInterceptors(FileInterceptor('media', {
    storage: diskStorage({
      destination: (req, file, cb) => {
        const uploadPath = join(process.cwd(), 'uploads');
        mkdirSync(uploadPath, { recursive: true });
        cb(null, uploadPath);
      },
      filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
        cb(null, uniqueSuffix + extname(file.originalname));
      }
    }),
    fileFilter: (req, file, cb) => {
      // Accept images, videos and audio
      if (!file.originalname.match(/\.(jpg|jpeg|png|gif|mp4|mov|avi|mkv|webm|mp3|wav|m4a|ogg)$/i)) {
        return cb(new Error('Only image, video, and audio files are allowed!'), false);
      }
      cb(null, true);
    }
  }))
  uploadMedia(@UploadedFile() file: Express.Multer.File) {
    if (!file) {
      return { success: false, message: 'No file uploaded' };
    }
    
    // Return relative path. The frontend's api_service handles adding the base url
    return { 
      success: true, 
      data: { url: `/uploads/${file.filename}` } 
    };
  }
}
