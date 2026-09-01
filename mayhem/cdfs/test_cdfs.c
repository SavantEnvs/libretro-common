#include <stdio.h>
#include <stdlib.h>
#include <formats/cdfs.h>

int main(int argc, char* argv[])
{
   cdfs_track_t* track;

   if (argc < 2)
   {
      fprintf(stderr, "usage: %s <track.cue>\n", argv[0]);
      return 1;
   }

   track = cdfs_open_track(argv[1], 1);

   if (track)
   {
      printf("Track Opened\n");
      cdfs_close_track(track);
   }
   else
   {
      printf("Failed to open track\n");
   }

   return 0;
}
